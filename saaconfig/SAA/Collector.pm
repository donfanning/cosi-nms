package SAA::Collector;

use strict;
require 5.002;
use lib qw(..);    # XXX This is for testing only.
use SNMP;
use SAA::SAA_MIB;
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

    if ( $args[3] ) {
        my $rc = _needTarget( $self->{operation}->{type} );
        $self->{target} = $args[3] if $rc;
    }

    bless( $self, $class );
    $self;
}
