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

1;
__END__
