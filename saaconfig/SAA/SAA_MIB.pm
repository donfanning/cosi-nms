package SAA::SAA_MIB;

use strict;
require 5.002;

use vars qw(@EXPORT_OK);
use vars qw($ciscoRttMonMIB $ciscoRttMonObjects $rttMonAppl $rttMonApplVersion $FALSE $TRUE);

use Exporter;
use Carp;

*import = \&Exporter::import;
@EXPORT_OK =
  qw($ciscoRttMonMIB $ciscoRttMonObjects $rttMonAppl $rttMonApplVersion $FALSE $TRUE);

$ciscoRttMonMIB     = '.1.3.6.1.4.1.9.9.42';
$ciscoRttMonObjects = $ciscoRttMonMIB . '.1';
$rttMonAppl         = $ciscoRttMonObjects . '.1';
$rttMonApplVersion  = $rttMonAppl . '.1';

# These are taken from the SNMPv2-TC definitions.  true is 1 and false is 2.
$TRUE = 1;
$FALSE = 2;

1;
__END__
