package SAA::Collector;

use strict;
require 5.002;
use lib qw(..);    # XXX This is for testing only.
use SNMP;
use SAA::Globals;
use SAA::SAA_MIB;
use Carp;

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
        name          => $args[0],
        id            => undef,
        source        => $args[1],
        operation     => $args[2],
        target        => undef,
        startTime     => SAA::SAA_MIB::DEFAULT_START_TIME,
        life          => SAA::SAA_MIB::DEFAULT_LIFE,
        writeNVRAM    => SAA::SAA_MIB::FALSE,
        historyFilter => $SAA::SAA_MIB::historyFilterEnum->{none},
        error         => undef,
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

    if ( scalar(@_) != 1 ) {
        croak "SAA::Collector::_needTarget: method requires one argument";
    }

    # This is a private static method to determine if a given operation type
    # needs a target.  HTTP, DNS, and DHCP operations do not need targets.
    my $type = shift;

    if ( $type == $SAA::SAA_MIB::operationTypeEnum->{dns}
        || $type == $SAA::SAA_MIB::operationTypeEnum->{http}
        || $type == $SAA::SAA_MIB::operationTypeEnum->{dhcp} )
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
        $self->{id} = int( rand 65535 ) + 1;
    }
    return $self->{id};
}

sub write_nvram {
    my $self = shift;
    if (@_) {
        my $val = shift;
        if ( $val != SAA::SAA_MIB::TRUE && $val != SAA::SAA_MIB::FALSE ) {
            return $self->{writeNVRAM};
        }
        $self->{writeNVRAM} = $val;
    }
    return $self->{writeNVRAM};
}

sub history_filter {
    my $self = shift;
    my $filter;
    if (@_) {
        my $val = shift;
        foreach ( keys %{$SAA::SAA_MIB::historyFilterEnum} ) {
            if ( $val == $SAA::SAA_MIB::historyFilterEnum->{$_} ) {
                $filter = $val;
                last;
            }
        }
        if ( !$filter ) {
            return $self->{historyFilter};
        }
        $self->{historyFilter} = $filter;
    }
    return $self->{historyFilter};
}

sub life {
    my $self = shift;
    if (@_) {
        my $duration = shift;
        if ( $duration < SAA::SAA_MIB::MIN_LIFE
            || $duration > SAA::SAA_MIB::MAX_LIFE )
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

    # Since this objet represents TimeTicks, it can have pretty much any range.
    # We cast the value to an int which should make things safe.
    if (@_) { $self->{startTime} = int(shift); }
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

    if ( $source->status() != SAA::Globals::HOST_UP_SNMP ) {
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
                $SAA::SAA_MIB::rttMonCtrlAdminStatus,          $id,
                $SAA::SAA_MIB::rowStatusEnum->{createAndWait}, 'INTEGER'
            ]
        )
    );

    if ( $sess->{ErrorNum} ) {
        $self->error("Failed to set row status");
        return;
    }
    my $varlist = new SNMP::VarList(
        [
            $SAA::SAA_MIB::rttMonCtrlAdminRttType, $id,
            $operation->type(),                    'INTEGER'
        ],
        [
            $SAA::SAA_MIB::rttMonEchoAdminProtocol, $id,
            $operation->protocol(),                 'INTEGER'
        ],
        [
            $SAA::SAA_MIB::rttMonEchoAdminSourceAddress, $id,
            addrToOctStr( $source->addr() ),            'OCTETSTR'
        ],
        [
            $SAA::SAA_MIB::rttMonEchoAdminSourcePort, $id,
            $operation->source_port(),                'INTEGER'
        ],
        [
            $SAA::SAA_MIB::rttMonEchoAdminTargetPort, $id,
            $operation->target_port(),                'INTEGER'
        ],
        [
            $SAA::SAA_MIB::rttMonEchoAdminControlEnable, $id,
            $operation->control_enable(),                'INTEGER'
        ],
        [
            $SAA::SAA_MIB::rttMonEchoAdminTOS, $id,
            $operation->tos(),                 'INTEGER'
        ],
        [
            $SAA::SAA_MIB::rttMonEchoAdminNameServer,   $id,
            addrToOctStr( $operation->name_server() ), 'OCTETSTR'
        ],
    );

# Add objects that may be undef for certain operations.
	if ($target) {
		push @{$varlist}, [ $SAA::SAA_MIB::rttMonEchoAdminTargetAddress, $id,
		addrToOctStr( $target->addr() ), 'OCTSTR' ];
	}

    # Set the objects on the source router.
    $sess->set($varlist);

    if ( $sess->{ErrorNum} ) {
        $self->error( "Failed to set collector, " . $self->{name} );
        return;
    }
}

1;
