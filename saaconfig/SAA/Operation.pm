package SAA::Operation;

use strict;
require 5.002;
use lib qw(..);    # XXX This is for testing only.
use SNMP;
use SAA::SAA_MIB;
use Carp;

# Define global protocols
$SAA::Operation::PROTO_NA                 = 1;
$SAA::Operation::PROTO_ICMP_ECHO          = 2;
$SAA::Operation::PROTO_UDP_ECHO           = 3;
$SAA::Operation::PROTO_SNA_RU_ECHO        = 4;
$SAA::Operation::PROTO_SNA_LU0_ECHO_APPL  = 5;
$SAA::Operation::PROTO_SNA_LU2_ECHO_APPL  = 6;
$SAA::Operation::PROTO_SNA_LU62_ECHO      = 7;
$SAA::Operation::PROTO_SNA_LU62_ECHO_APPL = 8;
$SAA::Operation::PROTO_TCP_CONN           = 24;
$SAA::Operation::PROTO_HTTP_APPL          = 25;
$SAA::Operation::PROTO_DNS_APPL           = 26;
$SAA::Operation::PROTO_JITTER_APPL        = 27;
$SAA::Operation::PROTO_DLSW_APPL          = 28;
$SAA::Operation::PROTO_DHCP_APPL          = 29;
$SAA::Operation::PROTO_FTP_APPL           = 30;

# End protocol definitions

# Define global operation types
$SAA::Operation::TYPE_NA        = 0;    # Note: this is not defined in the MIB
$SAA::Operation::TYPE_ECHO      = 1;
$SAA::Operation::TYPE_PATH_ECHO = 2;
$SAA::Operation::TYPE_FILE_IO   = 3;    # NOT SUPPORTED
$SAA::Operation::TYPE_SCRIPT    = 4;    # NOT SUPPORTED
$SAA::Operation::TYPE_UDP_ECHO  = 5;
$SAA::Operation::TYPE_TCP_CONN  = 6;
$SAA::Operation::TYPE_HTTP      = 7;
$SAA::Operation::TYPE_DNS       = 8;
$SAA::Operation::TYPE_JITTER    = 9;
$SAA::Operation::TYPE_DLSW      = 10;
$SAA::Operation::TYPE_DHCP      = 11;
$SAA::Operation::TYPE_FTP       = 12;

# End type definitions

# Define global defaults
$SAA::Operation::DEFAULT_THRESHOLD      = 5000;
$SAA::Operation::DEFAULT_FREQUENCY      = 60;
$SAA::Operation::DEFAULT_TIMEOUT        = 5000;
$SAA::Operation::DEFAULT_VERIFY         = $SAA::SAA_MIB::FALSE;
$SAA::Operation::DEFAULT_TOS            = 0;
$SAA::Operation::DEFAULT_CONTROL_ENABLE = $SAA::SAA_MIB::TRUE;
$SAA::Operation::DEFAULT_SPORT          = 0;
$SAA::Operation::DEFAULT_TPORT          = 0;

# Define global limits
$SAA::Operation::MIN_THRESHOLD = 0;
$SAA::Operation::MIN_TIMEOUT   = 0;
$SAA::Operation::MIN_SPORT     = 0;
$SAA::Operation::MIN_TPORT     = 0;
$SAA::Operation::MAX_FREQUENCY = 604800;
$SAA::Operation::MAX_TIMEOUT   = 604800000;
$SAA::Operation::MAX_THRESHOLD = 2147483647;
$SAA::Operation::CONTROL       = 0;
$SAA::Operation::MAX_SPORT     = 65536;
$SAA::Operation::MAX_TPORT     = 65536;

# End limit definitions

sub new {

    # ARG 1: String name
    # ARG 2: int type
    # ARG 3: int proto

    # This constructor creates new SAA operations.  It accepts three mandatory
# arguments, the operation name, the operation protocol, the operation type.  
    # Once the class is instantiated, use the accessor methods to configure the 
    # class properties.
    my ( $that, @args ) = @_;
    my $class = ref($that) || $that;

    if ( scalar(@args) != 3 ) {
        croak "SAA::Operation: Insufficient arguments passed to constructor";
    }

    my $self = {
        name             => $args[0],
        type             => $SAA::Operation::TYPE_NA,
        protocol         => $SAA::Operation::PROTO_NA,
        threshold        => $SAA::Operation::DEFAULT_THRESHOLD,
        frequency        => $SAA::Operation::DEFAULT_FREQUENCY,
        timeout          => $SAA::Operation::DEFAULT_TIMEOUT,
        verify           => $SAA::Operation::DEFAULT_VERIFY,
        tos              => $SAA::Operation::DEFAULT_TOS,
        targetPort       => $SAA::Operation::DEFAULT_TPORT,
        sourceAddress    => '',
        sourcePort       => $SAA::Operation::DEFAULT_SPORT,
        controlEnable    => $SAA::Operation::DEFAULT_CONTROL_ENABLE,
        dnsTargetAddress => '',
    };

    my $rc = _validateTypeProto( $args[1], $args[2] );
    return unless $rc;
    $self->{type}     = $args[1];
    $self->{protocol} = $args[2];
    bless( $self, $class );
    $self;
}

sub _validateTypeProto {
    my ( $type, $proto ) = @_;

    # This is a private static method for testing whether or not the type and
    # protocol are compatible.  It returns 1 if they are, undef otherwise.

    if ( $type == $SAA::Operation::TYPE_ECHO ) {
        return
          unless ( $proto == $SAA::Operation::PROTO_ICMP_ECHO
            || $proto == $SAA::Operation::PROTO_SNA_RU_ECHO
            || $proto == $SAA::Operation::PROTO_SNA_LU0_ECHO_APPL
            || $proto == $SAA::Operation::PROTO_SNA_LU2_ECHO_APPL
            || $proto == $SAA::Operation::PROTO_SNA_LU62_ECHO
            || $proto == $SAA::Operation::PROTO_SNA_LU62_ECHO_APPL );
    }
    elsif ( $type == $SAA::Operation::TYPE_PATH_ECHO ) {
        return unless ( $proto == $SAA::Operation::PROTO_ICMP_ECHO );
    }
    elsif ( $type == $SAA::Operation::TYPE_TCP_CONN ) {
        return unless ( $proto == $SAA::Operation::PROTO_TCP_CONN );
    }
    elsif ( $type == $SAA::Operation::TYPE_HTTP ) {
        return unless ( $proto == $SAA::Operation::PROTO_HTTP );
    }
    elsif ( $type == $SAA::Operation::TYPE_DNS ) {
        return unless ( $proto == $SAA::Operation::PROTO_DNS );
    }
    elsif ( $type == $SAA::Operation::TYPE_DHCP ) {
        return unless ( $proto == $SAA::Operation::PROTO_DHCP );
    }
    else {
        return;
    }

    1;
}

sub name {
    my $self = shift;

    # Name is static once the class has been instantiated.
    return $self->{name};
}

sub type {
    my $self = shift;

    # Type is static once the class has been instantiated.
    return $self->{type};
}

sub protocol {
    my $self = shift;

    # Protocol is static once the class has been instantiated.
    return $self->{protocol};
}

sub threshold {
    my $self = shift;

    # Threshold is valid for all SAA operations.
    if (@_) {
        my $th = shift;
        if ( $th < $SAA::Operation::MIN_THRESHOLD || $th > $self->timeout()
            || $th > $SAA::Operation::MAX_THRESHOLD )
        {
            return $self->{threshold};
        }
        $self->{threshold} = $th;
    }
    return $self->{threshold};
}

sub timeout {
    my $self = shift;

    # Timeout is valid for all SAA operations.
    if (@_) {
        my $timeout = shift;
        if ( $timeout < $SAA::Operation::MIN_TIMEOUT
            || $timeout < $self->threshold()
            || $timeout > $SAA::Operation::MAX_TIMEOUT )
        {
            return $self->{timeout};
        }
        $self->{timeout} = $timeout;
    }
    return $self->{timeout};
}

sub frequency {
    my $self = shift;

    # Frequency is valid for all SAA operations.
    if (@_) {
        my $frequency = shift;
        if ( $frequency < $SAA::Operation::MIN_FREQUENCY
            || $frequency < $self->timeout()
            || $frequency > $SAA::Operation::MAX_FREQUENCY )
        {
            return $self->{frequency};
        }
        $self->{frequency} = $frequency;
    }
    return $self->{frequency};
}

sub tos {
    my $self = shift;

    # This field is not applicable to DHCP or DNS operations.
    if ( $self->{type} == $SAA::Operation::TYPE_DNS
        || $self->{type} == $SAA::Operation::TYPE_DHCP )
    {

        # Return DEFAULT_TOS here (i.e. 0 for now; I guess it could change...)
        return $SAA::Operation::DEFAULT_TOS;
    }
    if (@_) {
        my $tos = shift;
        if ( $tos < $SAA::Operation::MIN_TOS
            || $tos > $SAA::Operation::MAX_TOS )
        {
            return $self->{tos};
        }
        $self->{tos} = $tos;
    }
    return $self->{tos};
}

sub sourcePort {
    my $self = shift;

    # This field is not applicable to DNS, DLSw, or SNA operations.
    if ( $self->{type} == $SAA::Operation::TYPE_DNS
        || $self->{type} == $SAA::Operations::TYPE_DLSW
        || ( $self->{protocol} > $SAA::Operation::PROTO_UDP_ECHO
            && $self->{protocol} <= $SAA::Operation::PROTO_SNA_LU62_ECHO_APPL )
      )
    {
        return $SAA::Operation::DEFAULT_SPORT;
    }

    if (@_) {
        my $sport = shift;
        if ( $sport < $SAA::Operation::MIN_SPORT
            || $sport > $SAA::Operation::MAX_SPORT )
        {
            return $self->{sourcePort};
        }
        $self->{sourcePort} = $sport;
    }
    return $self->{sourcePort};
}

sub targetPort {
    my $self = shift;

    # This field is applicable to udpEcho, tcpConnect, and jitter operations.
    if ( $self->{type} != $SAA::Operation::TYPE_UDP_ECHO
        && $self->{type} != $SAA::Operation::TYPE_TCP_CONN
        && $self->{type} != $SAA::Operation::TYPE_JITTER )
    {
        return $SAA::Operation::DEFAULT_TPORT;
    }

    if (@_) {
        my $tport = shift;
        if ( $tport < $SAA::Operation::MIN_TPORT
            || $tport > $SAA::Operation::MAX_TPORT )
        {
            return $self->{targetPort};
        }
        $self->{targetPort} = $tport;
    }
    return $self->{targetPort};
}

sub control_enabled {
    my $self = shift;

    # This field is not applicable to echo, pathEcho, dns and http operations.
    if ( $self->{type} == $SAA::Operations::TYPE_ECHO
        || $self->{type} == $SAA::Operations::TYPE_PATH_ECHO
        || $self->{type} == $SAA::Operations::TYPE_DNS
        || $self->{type} == $SAA::Operations::TYPE_HTTP )
    {
        return $SAA::Operations::DEFAULT_CONTROL_ENABLE;
    }

    if (@_) {
        my $control = shift;
        if ( $control != $SAA::SAA_MIB::TRUE
            && $control != $SAA::SAA_MIB::FALSE )
        {
            return $self->{controlEnable};
        }
        $self->{controlEnable} = $control;
    }
    return $self->{controlEnable};
}

1;
