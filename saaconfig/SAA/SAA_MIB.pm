package SAA::SAA_MIB;

use strict;
require 5.002;

use vars qw(@EXPORT_OK);
use vars qw($ciscoRttMonMIB $ciscoRttMonObjects $rttMonAppl $rttMonApplVersion);

use Exporter;
use Carp;

*import = \&Exporter::import;
@EXPORT_OK =
  qw($ciscoRttMonMIB $ciscoRttMonObjects $rttMonAppl $rttMonApplVersion);

$ciscoRttMonMIB     = '.1.3.6.1.4.1.9.9.42';
$ciscoRttMonObjects = $ciscoRttMonMIB . '.1';
$rttMonAppl         = $ciscoRttMonObjects . '.1';
$rttMonApplVersion  = $rttMonAppl . '.1';

1;
__END__
