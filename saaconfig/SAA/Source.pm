package SAA::Source;

use strict;
require 5.002;
use lib qw(..);
use SNMP;
use SAA::Globals;
use SAA::SAA_MIB;
use Crypt::CBC;
use Carp;

# Right now, we'll configure for v1/v2c.
sub new {
    my ( $that, @args ) = @_;
    my $class = ref($that) || $that;

	if (scalar(@args) != 3) {
		croak "SAA::Source: Insufficient arguments passed to constructor.";
	}

    my $self = {
        name        => $args[0],
        address     => $args[1],
        community   => $args[2],
        SNMPVersion => undef,
        SAAVersion  => undef,
        IOSVersion  => undef,
        status      => $SAA::Globals::HOST_DOWN,
    };

    bless( $self, $class );
    $self;
}

sub name {
    my $self = shift;
    if (@_) { $self->{name} = shift; }
    return $self->{name};
}

sub addr {
    my $self = shift;
    if (@_) { $self->{address} = shift; }
    return $self->{address};
}

sub snmp_version {
    my $self = shift;
    if (@_) { $self->{SNMPVersion} = shift; }
    return $self->{SNMPVersion};
}

sub community {
    my $self      = shift;
    my $encrypted = 0;
    $encrypted = shift if (@_);

    if (@_) {

        # Store the community string in a Blowfish cipher in the memory
        # and in the database.
        my $comm = shift;
        if ($encrypted) {
            $self->{community} = $comm;
            return $self->{community};
        }
        my $cipher = new Crypt::CBC( $SAA::Globals::KEY, 'Crypt::Blowfish' );

        $self->{community} = $cipher->encrypt_hex($comm);
    }

    if ($encrypted) {
        return $self->{community};
    }
    my $cipher = new Crypt::CBC( $SAA::Globals::KEY, 'Crypt::Blowfish' );
    my $comm   = $cipher->decrypt_hex($self->{community});

    return $comm;
}

sub saa_version {

    # This is the get version of the method only.  The set version of this
    # method is private.
    my $self = shift;
    return $self->{SAAVersion};
}

sub _saa_version {
    my $self = shift;
    $self->{SAAVersion} = shift;
}

sub ios_version {

    # This works the same way as SAA version.  This is the public
    # accessor method.
    my $self = shift;
    return $self->{IOSVersion};
}

sub _ios_version {
    my $self = shift;
    $self->{IOSVersion} = shift;
}

sub status {

    # Again, another public method like SAA and IOS Version.
    my $self = shift;
    return $self->{status};
}

sub _status {
    my $self = shift;
    $self->{status} = shift;
}

sub learn {

    # This method connects to the device, and populates the SNMP-retrieved
    # fields like IOS version, SAA version, etc.  It returns 0 if a device
    # does not support SAA.  Else, it will return 1.  Use status() to 
    # determine the status of the device.
    #
    # This method will try v2c if the device claims to support v2c.  If v2c
    # fails, it will fallback to v1.
    my $self = shift;
    return 0 unless ( defined $self->addr() && defined $self->community() );

    $self->snmp_version("1") unless defined $self->snmp_version();

    my $sess = new SNMP::Session(
        DestHost  => $self->addr(),
        Community => $self->community(),
        Version   => $self->snmp_version()
    );

    my ( $vars, @vals, $saavers, $iosvers );

    if ( $self->snmp_version() eq "2c" ) {
        $vars =
          new SNMP::VarList( [$SAA::SAA_MIB::rttMonApplVersion], ['system'] );
        @vals = $sess->getbulk( 1, 1, $vars );

        # XXX Note, -7 may change as the ErrorNum in the future.  However,
        # for now, it is the best way of determining if we're hitting a PDU
        # version problem.
        if ( $sess->{ErrorNum} == -7 ) {

            # SNMPv2c not supported!
            $self->snmp_version("1");
        }
        else {
            ($saavers) = ( $vals[0] =~ /(^[\d\.]+)/ );
            ($iosvers) = ( $vals[1] =~ /Version ([\d\.\w\(\)]+)/ );
            return 0 unless length $saavers;
            $self->_status($SAA::Globals::HOST_UP_SNMP);
        }
    }

    if ( $self->snmp_version() eq "1" ) {
        $vars =
          new SNMP::VarList( [ $SAA::SAA_MIB::rttMonApplVersion, 0 ],
            [ 'system', 0 ] );
        @vals = $sess->get($vars);
        if ( $sess->{ErrorNum} ) {
            return 0;
        }
        else {
            ($saavers) = ( $vals[0] =~ /(^[\d\.]+)/ );
            ($iosvers) = ( $vals[1] =~ /Version ([\d\.\w\(\)]+)/ );
            return 0 unless length $saavers;
            $self->_status($SAA::Globals::HOST_UP_SNMP);
        }
    }

    $self->_saa_version($saavers);
    $self->_ios_version($iosvers);

    1;

}

1;
__END__
