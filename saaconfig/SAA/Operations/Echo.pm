package SAA::Operations::Echo;

use strict;
require 5.002;
use lib qw(../..);
use SNMP;
use SAA::Operations;

sub new {

    # This constructor create a new ipEcho operation class.  It accepts no
    # arguments as it is designed to do the defaults.  To use the class, 
    # instatiate a new instance of it, then use the accessor methods to update
    # the class properties.
    my ( $that, @args ) = @_;
    my $class = ref($that) || $that;

    my $self = {
        Name      => 'Default IP Echo Operation',
        Type      => $SAA::Operations::TYPE_ECHO,
        Protocol  => $SAA::Operations::PROTO_ICMP_ECHO,
        Threshold => 5000,
        Frequency => 60,
        Timeout   => 5000,
        ToS       => 0,
    };

    bless( $self, $class );
    $self;
}

use Alias qw(attr);
use vars qw(
  $Name
  $Type
  $Protocol
  $Threshold
  $Frequency
  $Timeout
  $ToS
);

sub name {
    my $self = attr shift;
    if (@_) { $Name = shift; }
    return $Name;
}

sub type {

    # Type is a constant.
    my $self = attr shift;
    return $Type;
}

sub protocol {

# Protocol can either be ipIcmpEcho, ipUdpEchoAppl, snaRUEcho, snaLU0EchoAppl,
    # snaLU2EchoAppl, snaLU62Echo, or snaLU62EchoAppl.
    my $self = attr shift;
    if (@_) { $Protocol = shift; }
    return $Protocol;
}

sub threshold {
    my $self = attr shift;
    if (@_) {
        my $threshold = shift;
        if ( $threshold < 0 || $threshold > $self->timeout()
          || $threshold > $SAA::Operations::MAX_THRESHOLD )
        {
            return $Threshold;
        }
        $Threshold = $threshold;
    }
    return $Threshold;
}

sub timeout {
    my $self = attr shift;
    if (@_) {
        my $timeout = shift;
        if ( $timeout < 0 || $timeout < $self->threshold()
          || $timeout > $SAA::Operations::MAX_TIMEOUT )
        {
            return $Timeout;
        }
        $Timeout = $timeout;
    }
    return $Timeout;
}

sub frequency {
    my $self = attr shift;
    if (@_) {
        my $frequency = shift;

        # Per the MIB, this value cannot be less than $Timeout.
        if ( $frequency < 0 || $frequency < $self->timeout()
          || $frequency > $SAA::Operations::MAX_FREQUENCY )
        {
            return $Frequency;
        }
        $Frequency = $frequency;
    }
    return $Frequency;
}

sub tos {
    my $self = attr shift;
    if (@_) {
        my $tos = shift;
        if ( $tos < 0 || $tos > 255 ) {
            return $ToS;
        }
        $ToS = $tos;
    }
    return $ToS;
}
