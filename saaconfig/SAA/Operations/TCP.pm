package SAA::Operations::TcpCon;

use strict;
require 5.002;
use lib qw(../..);
use SNMP;
use SAA::Operations;

# XXX ----- UNTESTED -----
# This was simply written to get it
# out so that we can get all Operations
# Completed. I took the Echo.pm and Edited it for TCP Conn
# Probably a lot of things left out.  
# Nick -oo- 

sub new {

    # This constructor create a new ipEcho operation class.  It accepts no
    # arguments as it is designed to do the defaults.  To use the class, 
    # instatiate a new instance of it, then use the accessor methods to update
    # the class properties.
    my ( $that, @args ) = @_;
    my $class = ref($that) || $that;

    my $self = {
		# Hell Are there diffent Kinds of TCP connects?  Need to keep reading :)
        Name      => 'Default TCP Connect Operation',
        Type      => $SAA::Operations::TYPE_TCP_CONN,
        Protocol  => $SAA::Operations::PROTO_TCP_CONN,
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


# XXX - Should we even keep this sub here from tcpConnect? Nick -oo-
# Protocol can tcpConnect
    
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
