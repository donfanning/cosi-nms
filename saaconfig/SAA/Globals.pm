package SAA::Globals;

use strict;
require 5.002;

use Exporter;
use Carp;

my @ISA    = qw(Exporter);
my @EXPORT = qw(
  KEY
  PAD
  HOST_DOWN
  HOST_UP_IP
  HOST_UP_SNMP
  SNMP_ERR_NOSUCHNAME
  SNMP_ERR_V2_IN_V1
  SNMP_ERR_BAD_VERSION
  addrToOctStr
  checkIPAddr
);

# Random key used in Blowfish ciphering.
# XXX This key should not be statically defined here.  In the release, this
# should be configurable by the end user so that all keys will be different.
use constant KEY => pack( "H16", 'aIC9e8!Cmtdyu4GV' );
use constant PAD => 'aBcDeFg';

use constant HOST_DOWN    => 0;
use constant HOST_UP_IP   => 1;
use constant HOST_UP_SNMP => 2;

# Define some common ucd-snmp return codes.
use constant SNMP_ERR_NOSUCHNAME  => 2;
use constant SNMP_ERR_V2_IN_V1    => -7;
use constant SNMP_ERR_BAD_VERSION => -14;

# Public static methods
sub addrToOctStr {

    if ( scalar(@_) != 1 ) {
        croak "SAA::Globals::addrToOctStr: method requires one argument";
    }

    # Public static method to convert an IP address string into a 4-byte
    # octet string.  
    # XXX This should be smarter so that SNA address can also be supported.
    my $addr = shift;
    my ( $a, $b, $c, $cidr ) = split ( /\./, $addr, 4 );
	return ( "$a $b $c $cidr" );
    #return ( sprintf "%.2x %.2x %.2x %.2x", $a, $b, $c, $cidr );
}

sub checkIPAddr {

    if ( scalar(@_) != 1 ) {
        croak "SAA::Globals::checkIPAddr: method requires one argument";
    }

    my $addr   = shift;
    my @octets = split ( /\./, $addr );

    if ( scalar(@octets) != 4 ) {
        return;
    }

    foreach (@octets) {
        /^\d+$/ or return;
    }

    1;
}

1;
__END__
