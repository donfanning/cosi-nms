#
# $Id$
#
package SAA::Source;

use strict;
require 5.002;
use lib qw(..);
use SNMP;
use SAA::Globals;
use conf::prefs qw($KEY);
use SAA::SAA_MIB;
use Carp;
use Crypt::CBC;

# Right now, we'll configure for v1/v2c.
sub new {
    my ( $that, @args ) = @_;
    my $class = ref($that) || $that;

    if ( scalar(@args) != 3 ) {

        # This is an extremely fatal error.  This keeps a Source from being
        # properly instantiated.
        croak "SAA::Source: Insufficient arguments passed to constructor";
    }

    my $self = {
        name               => $args[0],
        address            => undef,
        readCommunity      => undef,
        writeCommunity     => undef,
        SNMPVersion        => $args[2],
        SAAVersion         => undef,
        IOSVersion         => undef,
        supportedTypes     => {},
        supportedProtocols => {},
        status             => HOST_DOWN,
        error              => undef,
    };

    my $addr = gethostbyname( $args[1] );
    $self->{address} = join ( '.', unpack( 'C4', $addr ) );

    bless( $self, $class );
    $self;
}

sub error {
    my $self = shift;
    if (@_) { $self->{error} = shift; }
    return $self->{error};
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

sub read_community {
    my $self      = shift;
    my $encrypted = 0;
    $encrypted = shift if (@_);

    if (@_) {

        # Store the community string in a Blowfish cipher in the memory
        # and in the database.
        my $comm = shift;
        if ($encrypted) {
            $self->{readCommunity} = $comm;
            return $self->{readCommunity};
        }
        my $cipher = new Crypt::CBC( $KEY, 'Crypt::Blowfish' );

        $self->{readCommunity} = $cipher->encrypt_hex($comm);
    }

    if ($encrypted) {
        return $self->{readCommunity};
    }
    my $cipher = new Crypt::CBC( $KEY, 'Crypt::Blowfish' );
    my $comm = $cipher->decrypt_hex( $self->{readCommunity} );

    return $comm;
}

sub write_community {
    my $self      = shift;
    my $encrypted = 0;
    $encrypted = shift if (@_);

    if (@_) {

        # Store the community string in a Blowfish cipher in the memory
        # and in the database.
        my $comm = shift;
        if ($encrypted) {
            $self->{writeCommunity} = $comm;
            return $self->{writeCommunity};
        }
        my $cipher = new Crypt::CBC( $KEY, 'Crypt::Blowfish' );

        $self->{writeCommunity} = $cipher->encrypt_hex($comm);
    }

    if ($encrypted) {
        return $self->{writeCommunity};
    }
    my $cipher = new Crypt::CBC( $KEY, 'Crypt::Blowfish' );
    my $comm = $cipher->decrypt_hex( $self->{writeCommunity} );

    return $comm;
}

sub saa_version {

    # This is the get version of the method only.  The set version of this
    # method is protected.
    my $self = shift;
    return $self->{SAAVersion};
}

sub _saa_version {
    my $self  = shift;
    my $class = ref $self;
    croak "Attempt to call protected method" if ( $class !~ /^SAA::/  );
    $self->{SAAVersion} = shift;
}

sub _add_type_supported {
    my $self  = shift;
    my $class = ref $self;
    croak "Attempt to call protected method" if ( $class !~ /^SAA::/ );
    my $type = shift;
    $self->{supportedTypes}->{$type} = 1;
}

sub type_supported {

    # If an argument is specified, this method will return 1 if the 
    # type is supported, undef otherwise.  If no arguments are
    # specified, this method will return a reference to a hash
    # of supported types.
    my $self = shift;
    if (@_) {
        my $type = shift;
        return $self->{supportedTypes}->{$type};
    }
    return $self->{supportedTypes};
}

sub _add_protocol_supported {
    my $self  = shift;
    my $class = ref $self;
    croak "Attempt to call protected method" if ( $class !~ /^SAA::/ );
    my $protocol = shift;
    $self->{supportedProtocols}->{$protocol} = 1;
}

sub protocol_supported {

    # If an argument is specified, this method will return 1 if the 
    # protocol is supported, undef otherwise.  If no arguments are
    # specified, this method will return a reference to a hash
    # of supported protocols.
    my $self = shift;
    if (@_) {
        my $protocol = shift;
        return $self->{supportedProtocols}->{$protocol};
    }
    return $self->{supportedProtocols};
}

sub ios_version {

    # This works the same way as SAA version.  This is the public
    # accessor method.
    my $self = shift;
    return $self->{IOSVersion};
}

sub _ios_version {
    my $self  = shift;
    my $class = ref $self;
    croak "Attempt to call protected method" if ( $class !~ /SAA::/ );
    $self->{IOSVersion} = shift;
}

sub status {

    # Again, another public method like SAA and IOS Version.
    my $self = shift;
    return $self->{status};
}

sub _status {
    my $self  = shift;
    my $class = ref $self;
    croak "Attempt to call protected method" if ( $class !~ /SAA::/ );
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

    if ( !defined( $self->addr() ) || !defined( $self->read_community() )
        || !defined( $self->write_community() ) )
    {
        $self->error(
"Source must have IP address, read community, and read-write community set"
        );
        return;
    }

    $self->snmp_version("1") unless defined $self->snmp_version();

    my $sess = new SNMP::Session(
        DestHost  => $self->addr(),
        Community => $self->read_community(),
        Version   => $self->snmp_version()
    );

    my ( $vars, @vals, $saavers, $iosvers );

    if ( $self->snmp_version() eq "2c" ) {
        $vars =
          new SNMP::VarList( [$SAA::SAA_MIB::rttMonApplVersion], ['system'] );
        @vals = $sess->getbulk( 1, 1, $vars );

        if ( $sess->{ErrorNum} == SNMP_ERR_BAD_VERSION ) {

            # SNMPv2c not supported!
            $self->snmp_version("1");

            # We need to re-create session with the right version number.
            $sess = new SNMP::Session(
                DestHost  => $self->addr(),
                Community => $self->read_community(),
                Version   => $self->snmp_version()
            );

        }
        elsif ( $sess->{ErrorNum} == 0
            || $sess->{ErrorNum} == SNMP_ERR_NOSUCHNAME )
        {
            ($saavers) = ( $vals[0] =~ /(^[\d\.]+)/ );
            ($iosvers) = ( $vals[1] =~ /Version ([\d\.\w\(\)]+)/ );
        }
        else {
            $self->error("Unable to get IOS and SAA versions using SNMPv2c");
            return;
        }
    }

    if ( $self->snmp_version() eq "1" ) {
        $vars =
          new SNMP::VarList( [ $SAA::SAA_MIB::rttMonApplVersion, 0 ],
            [ 'sysDescr', 0 ] );
        @vals = $sess->get($vars);
        if ( $sess->{ErrorNum} ) {
            $self->error("Unable to get IOS and SAA versions using SNMPv1");
            return;
        }
        else {
            ($saavers) = ( $vals[0] =~ /(^[\d\.]+)/ );
            ($iosvers) = ( $vals[1] =~ /Version ([\d\.\w\(\)]+)/ );
        }
    }

# We need to test to make sure the read-write community string works.  We will
# first read sysLocation, then set it to the same value.  Some firewalls don't
    # like it when a SNMP GET and SET come from the same source port, so we'll
    # create two SNMP sessions.
    $sess = new SNMP::Session(
        DestHost  => $self->addr(),
        Community => $self->read_community(),
        Version   => $self->snmp_version()
    );
    my $loc = $sess->get('sysLocation.0');

    if ( $sess->{ErrorNum} ) {
        $self->error(
            "Failed checking read-write community string (" . $sess->{ErrorNum}
            . ")" );
        return;
    }

    $sess = new SNMP::Session(
        DestHost  => $self->addr(),
        Community => $self->write_community(),
        Version   => $self->snmp_version()
    );

    $sess->set( new SNMP::Varbind( [ 'sysLocation', 0, $loc, 'OCTETSTR' ] ) );

    if ( $sess->{ErrorNum} ) {
        $self->error("Read-write community string is invalid");
        return;
    }

    $self->_saa_version($saavers);
    $self->_status(HOST_UP_SNMP);
    $self->_ios_version($iosvers);

    if ( !length($saavers) ) {
        $self->error("Router does not support SAA");
        return;
    }

    # Now we need to check to see what operations are actually supported.
    # Yes, we could hard-code this since we know the version number, but
    # what if a new version comes out?  Best to ask the router.
    $sess = new SNMP::Session(
        DestHost  => $self->addr(),
        Community => $self->read_community(),
        Version   => $self->snmp_version()
    );

    # First get a list of the supported types.
    foreach ( keys %{$SAA::SAA_MIB::operationTypeEnum} ) {
        my $isSupported =
          $sess->get( $SAA::SAA_MIB::rttMonApplSupportedRttTypesValid . '.'
            . $SAA::SAA_MIB::operationTypeEnum->{$_} );
        $self->_add_type_supported($_)
          if ( $isSupported == SAA::SAA_MIB::TRUE );
    }

    # Now we get a list of the supported protocols.
    foreach ( keys %{$SAA::SAA_MIB::operationProtocolEnum} ) {
        my $isSupported =
          $sess->get( $SAA::SAA_MIB::rttMonApplSupportedProtocolsValid . '.'
            . $SAA::SAA_MIB::operationProtocolEnum->{$_} );
        $self->_add_protocol_supported($_)
          if ( $isSupported == SAA::SAA_MIB::TRUE );
    }

    1;
}

1;
__END__
