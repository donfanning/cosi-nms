package SAA::Globals;

use strict;
require 5.002;

# Module export
use vars qw(@EXPORT_OK);
use vars qw($KEY $PAD $HOST_DOWN $HOST_UP_IP $HOST_UP_SNMP);

use Exporter;
use Carp;

*import = \&Exporter::import;
@EXPORT_OK = qw($KEY $PAD $HOST_DOWN $HOST_UP_IP $HOST_UP_SNMP);

# Random key used in Blowfish ciphering.
# XXX This key should not be statically defined here.  In the release, this
# should be configurable by the end user so that all keys will be different.
$KEY = pack("H16", 'aIC9e8!Cmtdyu4GV');
$PAD = 'aBcDeFg';

$HOST_DOWN    = 0;
$HOST_UP_IP   = 1;
$HOST_UP_SNMP = 2;

1;
__END__
