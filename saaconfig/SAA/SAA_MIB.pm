package SAA::SAA_MIB;

use strict;
require 5.002;

use vars qw(
  $ciscoRttMonMIB
  $ciscoRttMonObjects
  $rttMonAppl
  $rttMonApplVersion
  $rttMonCtrl
  $rttMonCtrlAdminTable
  $rttMonCtrlAdminEntry
  $rttMonCtrlAdminStatus
  $rttMonApplSupportedRttTypesTable
  $rttMonApplSupportedProtocolsTable
  $rttMonApplSupportedProtocolsEntry
  $rttMonApplSupportedRttTypesEntry
  $rttMonApplSupportedProtocolsValid
  $rttMonApplSupportedRttTypesValid
  $rttMonEchoAdminTOS
  $rttMonEchoAdminTable
  $rttMonEchoAdminEntry
  $rttMonEchoAdminTargetAddress
  $rttMonEchoAdminTargetPort
  $rttMonEchoAdminSourceAddress
  $rttMonEchoAdminSourcePort
  $rttMonEchoAdminNameServer
  $rttMonEchoAdminControlEnable
  $rttMonEchoAdminProtocol
  $rttMonCtrlAdminRttType
  $rttMonEchoAdminOperation
  $rttMonEchoAdminString1
  $rttMonEchoAdminString2
  $rttMonEchoAdminString3
  $rttMonEchoAdminString4
  $rttMonEchoAdminString5
  $rttMonEchoAdminURL
  $historyFilterEnum
  $rowStatusEnum
  $httpOperationEnum
  $operationProtocolEnum
  $operationTypeEnum
);

use Exporter;
use Carp;

my @ISA    = qw(Exporter);
my @EXPORT =
  qw(
  $ciscoRttMonMIB
  $ciscoRttMonObjects
  $rttMonAppl
  $rttMonApplVersion
  $rttMonCtrl
  $rttMonCtrlAdminTable
  $rttMonCtrlAdminEntry
  $rttMonCtrlAdminStatus
  $rttMonApplSupportedRttTypesTable
  $rttMonApplSupportedProtocolsTable
  $rttMonApplSupportedProtocolsEntry
  $rttMonApplSupportedRttTypesEntry
  $rttMonApplSupportedProtocolsValid
  $rttMonApplSupportedRttTypesValid
  $rttMonEchoAdminTOS
  $rttMonEchoAdminTable
  $rttMonEchoAdminEntry
  $rttMonEchoAdminTargetAddress
  $rttMonEchoAdminTargetPort
  $rttMonEchoAdminSourceAddress
  $rttMonEchoAdminSourcePort
  $rttMonEchoAdminNameServer
  $rttMonEchoAdminControlEnable
  $rttMonEchoAdminProtocol
  $rttMonCtrlAdminRttType
  $rttMonEchoAdminOperation
  $rttMonEchoAdminString1
  $rttMonEchoAdminString2
  $rttMonEchoAdminString3
  $rttMonEchoAdminString4
  $rttMonEchoAdminString5
  $rttMonEchoAdminURL
  $historyFilterEnum
  FALSE
  TRUE
  $rowStatusEnum
  $httpOperationEnum
  $operationProtocolEnum
  $operationTypeEnum
  DEFAULT_THRESHOLD
  DEFAULT_FREQUENCY
  DEFAULT_TIMEOUT
  DEFAULT_VERIFY
  DEFAULT_TOS
  DEFAULT_CONTROL_ENABLE
  DEFAULT_SPORT
  DEFAULT_TPORT
  MIN_THRESHOLD
  MIN_TIMEOUT
  MIN_SPORT
  MIN_TPORT
  MIN_FREQUENCY
  MAX_FREQUENCY
  MIN_TOS
  MAX_TOS
  MAX_TIMEOUT
  MAX_THRESHOLD
  CONTROL
  MAX_SPORT
  MAX_TPORT
  MIX_LIFE
  MAX_LIFE
  MAX_HTTP_STRINGS
  MAX_HTTP_STRING_LEN
  MAX_URL_LEN
  DEFAULT_START_TIME
  DEFAULT_LIFE
  LIVE_FOREVER
  START_TIME_NOW
);

$ciscoRttMonMIB                    = '.1.3.6.1.4.1.9.9.42';
$ciscoRttMonObjects                = $ciscoRttMonMIB . '.1';
$rttMonAppl                        = $ciscoRttMonObjects . '.1';
$rttMonApplVersion                 = $rttMonAppl . '.1';
$rttMonCtrl                        = $ciscoRttMonObjects . '.2';
$rttMonCtrlAdminTable              = $rttMonCtrl . '.1';
$rttMonCtrlAdminEntry              = $rttMonCtrlAdminTable . '.1';
$rttMonCtrlAdminRttType            = $rttMonCtrlAdminEntry . '.4';
$rttMonCtrlAdminStatus             = $rttMonCtrlAdminEntry . '.9';
$rttMonApplSupportedRttTypesTable  = $rttMonAppl . '.7';
$rttMonApplSupportedProtocolsTable = $rttMonAppl . '.8';
$rttMonApplSupportedProtocolsEntry = $rttMonApplSupportedProtocolsTable . '.1';
$rttMonApplSupportedRttTypesEntry  = $rttMonApplSupportedRttTypesTable . '.1';
$rttMonApplSupportedProtocolsValid = $rttMonApplSupportedProtocolsEntry . '.2';
$rttMonApplSupportedRttTypesValid  = $rttMonApplSupportedRttTypesEntry . '.2';
$rttMonEchoAdminTable              = $rttMonCtrl . '.2';
$rttMonEchoAdminEntry              = $rttMonEchoAdminTable . '.1';
$rttMonEchoAdminProtocol           = $rttMonEchoAdminEntry . '.1';
$rttMonEchoAdminTargetAddress      = $rttMonEchoAdminEntry . '.2';
$rttMonEchoAdminTargetPort         = $rttMonEchoAdminEntry . '.5';
$rttMonEchoAdminSourceAddress      = $rttMonEchoAdminEntry . '.6';
$rttMonEchoAdminSourcePort         = $rttMonEchoAdminEntry . '.7';
$rttMonEchoAdminControlEnable      = $rttMonEchoAdminEntry . '.8';
$rttMonEchoAdminTOS                = $rttMonEchoAdminEntry . '.9';
$rttMonEchoAdminNameServer         = $rttMonEchoAdminEntry . '.12';
$rttMonEchoAdminOperation          = $rttMonEchoAdminEntry . '.13';
$rttMonEchoAdminURL                = $rttMonEchoAdminEntry . '.15';
$rttMonEchoAdminString1            = $rttMonEchoAdminEntry . '.20';
$rttMonEchoAdminString2            = $rttMonEchoAdminEntry . '.21';
$rttMonEchoAdminString3            = $rttMonEchoAdminEntry . '.22';
$rttMonEchoAdminString4            = $rttMonEchoAdminEntry . '.23';
$rttMonEchoAdminString5            = $rttMonEchoAdminEntry . '.24';

# These are taken from the SNMPv2-TC definitions.  true is 1 and false is 2.
use constant TRUE  => 1;
use constant FALSE => 2;

# Row status enum
$rowStatusEnum = {
    active        => 1,
    notInService  => 2,
    notReady      => 3,
    createAndGo   => 4,
    createAndWait => 5,
    destroy       => 6,
};

# Ref to hash indicating the values for rttMonHistoryAdminFilter.
$historyFilterEnum = {
    none          => 1,
    all           => 2,
    overThreshold => 3,
    failures      => 4,
};

$httpOperationEnum = {
    httpGet    => 1,
    httpRaw    => 2,
    ftpGet     => 3,
    ftpPassive => 4,
};

# Define global protocols
$operationProtocolEnum = {
    na                => 1,
    icmpEcho          => 2,
    udpEcho           => 3,
    snaRUEcho         => 4,
    snaLU0EchoAppl    => 5,
    snaLU2EchoAppl    => 6,
    snaLU62Echo       => 7,
    snaLU62EchoAppl   => 8,
    appleTalkEcho     => 9,
    appleTalkEchoAppl => 10,
    decNetEcho        => 11,
    decNetEchoAppl    => 12,
    ipxEcho           => 13,
    ipxEchoAppl       => 14,
    isoClnsEcho       => 15,
    isoClnsEchoAppl   => 16,
    vinesEcho         => 17,
    vinesEchoAppl     => 18,
    xnsEcho           => 19,
    xnsEchoAppl       => 20,
    apolloEcho        => 21,
    apolloEchoAppl    => 22,
    netbiosEchoAppl   => 23,
    ipTcpConn         => 24,
    httpAppl          => 25,
    dnsAppl           => 26,
    jitterAppl        => 27,
    dlswAppl          => 28,
    dhcpAppl          => 29,
    ftpAppl           => 30,
  },

  # End protocol definitions

  # Define global operation types
  $operationTypeEnum = {
    na         => 0,    # Note: this is not defined in the MIB
    echo       => 1,
    pathEcho   => 2,
    fileIO     => 3,    # NOT SUPPORTED
    script     => 4,    # NOT SUPPORTED
    udpEcho    => 5,
    tcpConnect => 6,
    http       => 7,
    dns        => 8,
    jitter     => 9,
    dlsw       => 10,
    dhcp       => 11,
    ftp        => 12,
};

# End type definitions

# Define global defaults
use constant DEFAULT_THRESHOLD      => 5000;
use constant DEFAULT_FREQUENCY      => 60;
use constant DEFAULT_TIMEOUT        => 5000;
use constant DEFAULT_VERIFY         => FALSE;
use constant DEFAULT_TOS            => 0;
use constant DEFAULT_CONTROL_ENABLE => TRUE;
use constant DEFAULT_SPORT          => 0;
use constant DEFAULT_TPORT          => 0;
use constant DEFAULT_START_TIME     => 0;
use constant DEFAULT_LIFE           => 3600;

# Define global limits
use constant MIN_THRESHOLD       => 0;
use constant MIN_TIMEOUT         => 0;
use constant MIN_SPORT           => 0;
use constant MIN_TPORT           => 0;
use constant MIN_FREQUENCY       => 0;
use constant MAX_FREQUENCY       => 604800;
use constant MIN_TOS             => 0;
use constant MAX_TOS             => 255;
use constant MAX_TIMEOUT         => 604800000;
use constant MAX_THRESHOLD       => 2147483647;
use constant CONTROL             => 0;
use constant MAX_SPORT           => 65536;
use constant MAX_TPORT           => 65536;
use constant MIN_LIFE            => 0;
use constant MAX_LIFE            => 2147483647;
use constant MAX_HTTP_STRINGS    => 5;
use constant MAX_HTTP_STRING_LEN => 255;
use constant MAX_URL_LEN         => 255;

# End limit definitions

# Collector globals
use constant START_TIME_NOW => 1;
use constant LIVE_FOREVER   => MAX_LIFE;

# End globals

1;
__END__
