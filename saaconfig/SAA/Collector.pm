package SAA::Collector;

use strict;
require 5.002;
use lib qw(..);    # XXX This is for testing only.
use SNMP;
use SAA::Globals;
use SAA::SAA_MIB;
use SAA::Operation;
use Carp;

# Default collector values
$SAA::Collector::DEFAULT_START_TIME = 0;
$SAA::Collector::DEFAULT_LIFE       = 3600;

# End defaults

# Collector maximums
$SAA::Collector::MAX_LIFE = 2147483647;

# End maximums

# Collector minimums
$SAA::Collector::MIN_LIFE = 0;

# End minimums

# Collector globals
$SAA::Collector::START_TIME_NOW = 1;
$SAA::Collector::LIVE_FOREVER   = $SAA::Collector::MAX_LIFE;

# End globals

sub new {

    # ARG 1: String name
    # ARG 2: SAA::Source source
    # ARG 3: SAA::Operation operation
    # ARG 4: (optional) SAA::Target target
    my ( $that, @args ) = @_;
    my $class = ref($that) || $that;

    if ( scalar(@args) < 3 || scalar(@args) > 4 ) {
        croak "SAA::Collector: Insufficient arguments passed to constructor";
    }

    my $self = {
        name      => $args[0],
        id        => undef,
        source    => $args[1],
        operation => $args[2],
        target    => undef,
        startTime => $SAA::Collector::DEFAULT_START_TIME,
        life      => $SAA::Collector::DEFAULT_LIFE,
        error     => undef,
    };

    my $rc = _needTarget( $self->{operation}->type() );
    if ( scalar(@args) == 4 && $rc ) {
        $self->{target} = $args[3];
    }
    elsif ( scalar(@args) < 4 && $rc ) {
        croak
          "SAA::Collector: The specified operation requires a target argument";
    }

    bless( $self, $class );
    $self;
}

sub _needTarget {

    # This is a private static method to determine if a given operation type
    # needs a target.  HTTP, DNS, and DHCP operations do not need targets.
    my $type = shift;

    if ( $type == $SAA::Operation::TYPE_DNS
        || $type == $SAA::Operation::TYPE_HTTP
        || $type == $SAA::Operations::TYPE_DHCP )
    {
        return 0;
    }

    1;
}

sub source {
    my $self = shift;
    return $self->{source};
}

sub target {
    my $self = shift;
    return $self->{target};
}

sub name {
    my $self = shift;
    return $self->{name};
}

sub id {
    my $self = shift;
    my ($override);

    if (@_) { $override = shift; }

    if ( !$self->{id} || $override ) {

        # Don't calculate id if it's already set or unless we're forced
        # to (by setting $override to 1).
        srand( time ^ $$ );    # We don't need the best seed.
        $self->{id} = int( rand 65534 ) + 1;
    }
    return $self->{id};
}

sub life {
    my $self = shift;
    if (@_) {
        my $duration = shift;
        if ( $duration < $SAA::Collector::MIN_LIFE
            || $duration > $SAA::Collector::MAX_LIFE )
        {
            return $self->{life};
        }
        else {
            $self->{life} = $duration;
        }
    }
    return $self->{life};
}

sub start_time {
    my $self = shift;
    if (@_) {
        my $start = shift;
        if ( $start < $SAA::Collector::MIN_START_TIME
            || $start > $SAA::MAX_START_TIME )
        {
            return $self->{startTime};
        }
        else {
            $self->{startTime} = $start;
        }
    }
    return $self->{startTime};
}

sub error {
    my $self = shift;
    if (@_) { $self->{error} = shift; }
    return $self->{error};
}

sub install {

    # This method installs the collector on the source router.  It 
    # assumes that the source has been successfully learned.
    my $self = shift;
    my ( $source, $target, $operation, $id, $sess );

    $source = $self->source();
    $target = $self->target();
    $id     = $self->id();

    if ( $source->status() != $SAA::Globals::HOST_UP_SNMP ) {
        $self->error( "Status for host " . $source->name()
            . " indicates it is not SNMP reachable" );
        return;
    }

    # For now, we use the read-only community string.  We'll change over
    # to read-write when we do the actual configuration.
    $sess = new SNMP::Session(
        DestHost  => $source->addr(),
        Community => $source->read_community(),
        Version   => $source->snmp_version(),
    );

    # We need to determine if the given $id is already in use on the 
    # source router.  We will loop ten times or until we find a free 
    # row id.
    my $i;
    for ( $i = 0 ; $i < 10 ; $i++ ) {
        my $val =
          $sess->get( $SAA::SAA_MIB::rttMonCtrlAdminStatus . '.' . $id );
        last if ( $sess->{ErrorNum} );
        $id = $self->id(1);    # Force a new id to be generated.
    }

    # This really shouldn't happen.
    if ( $i == 10 ) {
        $self->error("Unable to find a free row id after ten tries");
        return;
    }

    # Now that we have a valid row id, we can do the actual collector setup.
    $sess = new SNMP::Session(
        DestHost  => $source->addr(),
        Community => $source->write_community(),
        Version   => $source->snmp_version(),
    );

    # We will use the createAndWait method.
    $sess->set(
        new SNMP::Varbind(
            [
                $SAA::SAA_MIB::rttMonCtrlAdminStatus, $id,
                $SAA::SAA_MIB::createAndWait, 'INTEGER'
            ]
        )
    );

    if ( $sess->{ErrorNum} ) {
        $self->error("Failed to set row status");
        return;
    }
}

1;
