package SAA::Operation;

use strict;
require 5.002;
use lib qw(..);    # XXX This is for testing only.
use SNMP;
use SAA::SAA_MIB;
use Carp;

sub new {

    # ARG 1: String name
    # ARG 2: int type
    # ARG 3: int proto

    # This constructor creates new SAA operations.  It accepts three mandatory
    # arguments, the operation name, the operation protocol, the 
    # operation type.  Once the class is instantiated, use the accessor methods 
    # to configure the class properties.
    my ( $that, @args ) = @_;
    my $class = ref($that) || $that;

    if ( scalar(@args) != 3 ) {
        croak "SAA::Operation: Insufficient arguments passed to constructor";
    }

    my $self = {
        name             => $args[0],
        type             => $SAA::SAA_MIB::operationTypeEnum->{na},
        protocol         => $SAA::SAA_MIB::operationProtocolEnum->{na},
        threshold        => SAA::SAA_MIB::DEFAULT_THRESHOLD,
        frequency        => SAA::SAA_MIB::DEFAULT_FREQUENCY,
        timeout          => SAA::SAA_MIB::DEFAULT_TIMEOUT,
        verify           => SAA::SAA_MIB::DEFAULT_VERIFY,
        tos              => SAA::SAA_MIB::DEFAULT_TOS,
        targetPort       => SAA::SAA_MIB::DEFAULT_TPORT,
        sourcePort       => SAA::SAA_MIB::DEFAULT_SPORT,
        controlEnable    => SAA::SAA_MIB::DEFAULT_CONTROL_ENABLE,
        dnsTargetAddress => undef,
        adminOperation   => undef,
        adminStrings     => undef,
        adminURL         => undef,
        adminCache       => SAA::SAA_MIB::DEFAULT_ADMIN_CACHE,
        error            => undef,
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

    if ( scalar(@_) != 2 ) {
        croak
"SAA::Operation::_validateTypeProtocol: method requires two arguments";
    }

    # This is a private static method for testing whether or not the type and
    # protocol are compatible.  It returns 1 if they are, undef otherwise.

    if ( $type == $SAA::SAA_MIB::operationTypeEnum->{echo} ) {
        return
          unless ( $proto == $SAA::SAA_MIB::operationProtocolEnum->{icmpEcho}
            || $proto == $SAA::SAA_MIB::operationProtocolEnum->{snaRUEcho}
            || $proto == $SAA::SAA_MIB::operationProtocolEnum->{snaLU0EchoAppl}
            || $proto == $SAA::SAA_MIB::operationProtocolEnum->{snaLU2EchoAppl}
            || $proto == $SAA::SAA_MIB::operationProtocolEnum->{snaLU62Echo}
            || $proto ==
            $SAA::SAA_MIB::operationProtocolEnum->{snaLU62EchoAppl} );
    }
    elsif ( $type == $SAA::SAA_MIB::operationTypeEnum->{pathEcho} ) {
        return
          unless ( $proto == $SAA::SAA_MIB::operationProtocolEnum->{icmpEcho} );
    }
    elsif ( $type == $SAA::SAA_MIB::operationTypeEnum->{tcpConnect} ) {
        return
          unless (
            $proto == $SAA::SAA_MIB::operationProtocolEnum->{ipTcpConn} );
    }
    elsif ( $type == $SAA::SAA_MIB::operationTypeEnum->{http} ) {
        return
          unless ( $proto == $SAA::SAA_MIB::operationProtocolEnum->{httpAppl} );
    }
    elsif ( $type == $SAA::SAA_MIB::operationTypeEnum->{dns} ) {
        return
          unless ( $proto == $SAA::SAA_MIB::operationProtocolEnum->{dnsAppl} );
    }
    elsif ( $type == $SAA::SAA_MIB::operationTypeEnum->{dhcp} ) {
        return
          unless ( $proto == $SAA::SAA_MIB::operationProtocolEnum->{dhcpAppl} );
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
        if ( $th < SAA::SAA_MIB::MIN_THRESHOLD || $th > $self->timeout()
            || $th > SAA::SAA_MIB::MAX_THRESHOLD )
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
        if ( $timeout < SAA::SAA_MIB::MIN_TIMEOUT
            || $timeout < $self->threshold()
            || $timeout > SAA::SAA_MIB::MAX_TIMEOUT )
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
        if ( $frequency < SAA::SAA_MIB::MIN_FREQUENCY
            || $frequency < $self->timeout()
            || $frequency > SAA::SAA_MIB::MAX_FREQUENCY )
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
    if ( $self->type() == $SAA::SAA_MIB::operationTypeEnum->{dns}
        || $self->type() == $SAA::SAA_MIB::operationTypeEnum->{dhcp} )
    {

        # Return DEFAULT_TOS here (i.e. 0 for now; I guess it could change...)
        return SAA::SAA_MIB::DEFAULT_TOS;
    }
    if (@_) {
        my $tos = shift;
        if ( $tos < SAA::SAA_MIB::MIN_TOS || $tos > SAA::SAA_MIB::MAX_TOS ) {
            return $self->{tos};
        }
        $self->{tos} = $tos;
    }
    return $self->{tos};
}

sub source_port {
    my $self = shift;

    # This field is not applicable to DNS, DLSw, or SNA operations.
    if ( $self->type() == $SAA::SAA_MIB::operationTypeEnum->{dns}
        || $self->type() == $SAA::SAA_MIB::operationTypeEnum->{dlsw}
        || ( $self->protocol() > $SAA::SAA_MIB::operationProtocolEnum->{udpEcho}
            && $self->protocol() <=
            $SAA::SAA_MIB::operationProtocolEnum->{snaLU62EchoAppl} ) )
    {
        return SAA::SAA_MIB::DEFAULT_SPORT;
    }

    if (@_) {
        my $sport = shift;
        if ( $sport < SAA::SAA_MIB::MIN_SPORT
            || $sport > SAA::SAA_MIB::MAX_SPORT )
        {
            return $self->{sourcePort};
        }
        $self->{sourcePort} = $sport;
    }
    return $self->{sourcePort};
}

sub target_port {
    my $self = shift;

    # This field is applicable to udpEcho, tcpConnect, and jitter operations.
    if ( $self->type() != $SAA::SAA_MIB::operationTypeEnum->{udpEcho}
        && $self->type() != $SAA::SAA_MIB::operationTypeEnum->{tcpConnect}
        && $self->type() != $SAA::SAA_MIB::operationTypeEnum->{jitter} )
    {
        return SAA::SAA_MIB::DEFAULT_TPORT;
    }

    if (@_) {
        my $tport = shift;
        if ( $tport < SAA::SAA_MIB::MIN_TPORT
            || $tport > SAA::SAA_MIB::MAX_TPORT )
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
    if ( $self->type() == $SAA::SAA_MIB::operationTypeEnum->{echo}
        || $self->type() == $SAA::SAA_MIB::operationTypeEnum->{pathEcho}
        || $self->type() == $SAA::SAA_MIB::operationTypeEnum->{dns}
        || $self->type() == $SAA::SAA_MIB::operationTypeEnum->{http} )
    {
        return SAA::SAA_MIB::DEFAULT_CONTROL_ENABLE;
    }

    if (@_) {
        my $control = shift;
        if ( $control != SAA::SAA_MIB::TRUE && $control != SAA::SAA_MIB::FALSE )
        {
            return $self->{controlEnable};
        }
        $self->{controlEnable} = $control;
    }
    return $self->{controlEnable};
}

sub admin_operation {
    my $self = shift;
    my ( $val, $op );

    # This field is only applicable to http and ftp operations.
    if ( $self->type() != $SAA::SAA_MIB::operationTypeEnum->{http}
        && $self->type() != $SAA::SAA_MIB::operationTypeEnum->{ftp} )
    {

        # This field has no default value.
        return;
    }
    if (@_) {
        $val = shift;
        foreach ( keys %{$SAA::SAA_MIB::adminOperationEnum} ) {

            if ( $val == $SAA::SAA_MIB::adminOperationEnum->{$_} ) {
                $op = $val;
                last;
            }
        }

        if ( !$op ) {
            return $self->{adminOperation};
        }
        $self->{adminOperation} = $op;
    }
    return $self->{adminOperation};
}

sub admin_strings {
    my $self = shift;

    # This field is only applicable to http and dhcp operations.
    if ( $self->type() != $SAA::SAA_MIB::operationTypeEnum->{http}
        && $self->type() != $SAA::SAA_MIB::operationTypeEnum->{dhcp} )
    {
        return;
    }

    if (@_) {
        my $string = shift;
        my ( $i, $length, $limit );
        $i      = 0;
        $length = 0;

        # The dhcp operation only uses AdminString1.
        $limit =
          ( $self->type() == $SAA::SAA_MIB::operationTypeEnum->{http} ) ?
          SAA::SAA_MIB::MAX_ADMIN_STRINGS: 1;

        # This string has a cap.  If this string is longer than the max, we need
        # to chop it, and fit it into an array.

        while ( $i < $limit ) {
            while ( $length < length $string ) {
                push @{ $self->{adminStrings} }, substr( $string, $length,
                    SAA::SAA_MIB::MAX_ADMIN_STRING_LEN );
                $length += SAA::SAA_MIB::MAX_ADMIN_STRING_LEN;
            }
            $i++;
        }
    }
    return $self->{adminStrings};
}

sub admin_url {
    my $self = shift;

    # This field is only applicable to http and ftp operations.
    if ( $self->type() != $SAA::SAA_MIB::operationTypeEnum->{http}
        && $self->type() != $SAA::SAA_MIB::operationTypeEnum->{ftp} )
    {
        return;
    }

    if (@_) {
        my $url = shift;

        if ( length $url > SAA::SAA_MIB::MAX_URL_LEN ) {
            return $self->{adminURL};
        }
        $self->{adminURL} = $url;
    }
    return $self->{adminURL};
}

sub admin_cache {
    my $self = shift;

    # This field is only applicable to http operations.
    if ( $self->type() != $SAA::SAA_MIB::operationTypeEnum->{http} ) {
        return SAA::SAA_MIB::DEFAULT_ADMIN_CACHE;
    }

    if (@_) {
        my $cache = shift;

        if ( $cache != SAA::SAA_MIB::TRUE && $cache != SAA::SAA_MIB::FALSE ) {
            return $self->{adminCache};
        }
        $self->{adminCache} = $cache;
    }
    return $self->{adminCache};
}

sub name_server {
    my $self = shift;
    my $addr;

    if ( $self->type() != $SAA::SAA_MIB::operationTypeEnum->{dns} ) {
        return;
    }
    if (@_) {
        $addr = shift;
        if ( !checkIPAddr($addr) ) {
            return $self->{dnsTargetAddress};
        }
        $self->{dnsTargetAddress} = $addr;
    }
    return $self->{dnsTargetAddress};
}

1;
