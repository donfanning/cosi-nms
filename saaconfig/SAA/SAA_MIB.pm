package SAA::SAA_MIB;

use strict;
require 5.002;

use vars qw(@EXPORT_OK);
use vars qw(
  $ciscoRttMonMIB
  $ciscoRttMonObjects
  $rttMonAppl
  $rttMonApplVersion
  $rttMonCtrl
  $rttMonCtrlAdminTable
  $rttMonCtrlAdminEntry
  $rttMonCtrlAdminStatus
  $FALSE
  $TRUE
  $createAndWait
  $SNMP_ERR_NOSUCHNAME
  $SNMP_ERR_V2_IN_V1
  $SNMP_ERR_BAD_VERSION
);

use Exporter;
use Carp;

*import    = \&Exporter::import;
@EXPORT_OK =
  qw(
  $ciscoRttMonMIB
  $ciscoRttMonObjects
  $rttMonAppl
  $rttMonApplVersion
  $rttMonCtrl
  $rttMonCtrlAdminTable
  $rttMonCtrlAdminEntry
  $rttMonCtrlAdminStatus
  $FALSE
  $TRUE
  $createAndWait
  $SNMP_ERR_NOSUCHNAME
  $SNMP_ERR_V2_IN_V1
  $SNMP_ERR_BAD_VERSION
);

$ciscoRttMonMIB        = '.1.3.6.1.4.1.9.9.42';
$ciscoRttMonObjects    = $ciscoRttMonMIB . '.1';
$rttMonAppl            = $ciscoRttMonObjects . '.1';
$rttMonApplVersion     = $rttMonAppl . '.1';
$rttMonCtrl            = $ciscoRttMonObjects . '.2';
$rttMonCtrlAdminTable  = $rttMonCtrl . '.1';
$rttMonCtrlAdminEntry  = $rttMonCtrlAdminTable . '.1';
$rttMonCtrlAdminStatus = $rttMonCtrlAdminEntry . '.9';

# These are taken from the SNMPv2-TC definitions.  true is 1 and false is 2.
$TRUE          = 1;
$FALSE         = 2;
$createAndWait = 5;

# Define some common ucd-snmp return codes.
$SNMP_ERR_NOSUCHNAME  = 2;
$SNMP_ERR_V2_IN_V1    = -7;
$SNMP_ERR_BAD_VERSION = -14;

1;
__END__
