#
# $Id$
#
package SAA::Globals;

use strict;
require 5.002;

use vars qw(@ISA @EXPORT);
use Exporter;
use Carp;

@ISA    = qw(Exporter);
@EXPORT = qw(
  HOST_DOWN
  HOST_UP_IP
  HOST_UP_SNMP
  SNMP_ERR_NOSUCHNAME
  SNMP_ERR_V2_IN_V1
  SNMP_ERR_BAD_VERSION
  addrToOctStr
  addrToHexStr
  checkIPAddr
);

use constant HOST_DOWN    => 0;
use constant HOST_UP_IP   => 1;
use constant HOST_UP_SNMP => 2;

# Define some common ucd-snmp return codes.
use constant SNMP_ERR_NOSUCHNAME  => 2;
use constant SNMP_ERR_V2_IN_V1    => -7;
use constant SNMP_ERR_BAD_VERSION => -14;

# Public static methods
sub addrToOctStr {

        if (scalar(@_) != 1) {
                croak
                    "SAA::Globals::addrToOctStr: method requires one argument";
        }

        # Public static method to convert an IP address string into a 4-byte
        # octet string.
        # XXX This should be smarter so that SNA address can also be supported.
        my $addr = shift;
        my ($a, $b, $c, $cidr) = split (/\./, $addr, 4);
        return ("$a $b $c $cidr");

        #return ( sprintf "%.2x %.2x %.2x %.2x", $a, $b, $c, $cidr );
}

sub addrToHexStr {
    if ( scalar(@_) != 1 ) {
        croak "SAA::Globals::addrToHexStr: method requires one argument";
    }

	my $addr = shift ;
	my (@IP,  $IP_octet, @hex_IP, $hex_octet, $hex_IP);
    @IP = split ( /\./, $addr);
	foreach $IP_octet (@IP)	{
		$hex_octet = sprintf("%2.2x",$IP_octet);
		push @hex_IP, $hex_octet;
	}
	$hex_IP=join("", @hex_IP);

    return ( $hex_IP ) ;
}

sub checkIPAddr {

        if (scalar(@_) != 1) {
                croak "SAA::Globals::checkIPAddr: method requires one argument";
        }

        my $addr   = shift;
        my @octets = split (/\./, $addr);

        if (scalar(@octets) != 4) {
                return;
        }

        foreach (@octets) {
                /^\d+$/ or return;
        }

        1;
}

1;
__END__
