package conf::tables;

use strict;
use vars qw(@ISA @EXPORT_OK);
use Exporter;

@ISA       = qw(Exporter);
@EXPORT_OK = qw(
  $Create_Src
  $Create_Target
  $Create_Operation
  $Create_Collector
  $Create_User
  $Create_Ip_Echo_subop
);

use vars qw(
  $Create_Src
  $Create_Target
  $Create_Operation
  $Create_Collector
  $Create_User
  $Create_Ip_Echo_subop
);

$Create_Src = "CREATE TABLE IF NOT EXISTS SAA_SOURCES (
        SrcId int PRIMARY KEY,
        SrcAlias varchar(64) NOT NULL UNIQUE, 
        SrcIpAddr varchar(127) NOT NULL UNIQUE,
		SrcStatus int,
        SrcDescr varchar(255),
        SrcHostName varchar(64), 
        SrcReadComm varchar(32),
        SrcWriteComm varchar(32),
        SrcSnmpVersion varchar(2),
        SrcSupportedProtocols text,
		SrcSupportedTypes text,
        SrcIosVersion varchar(64),
        SrcRttAppVersion varchar(64)
        )";

$Create_Target = "CREATE TABLE IF NOT EXISTS SAA_TARGETS (
        TgtId int PRIMARY KEY,
        TgtAlias varchar(64) NOT NULL UNIQUE,
        TgtIpAddr varchar(127) NOT NULL UNIQUE,
		TgtStatus int,
        TgtDescr varchar(255),
        TgtHostName varchar (64),
        TgtReadComm varchar (32),
        TgtWriteComm varchar (32),
        TgtIosVersion varchar (64),
        TgtRttAppVersion varchar (64)
        )";

$Create_Operation = "CREATE TABLE IF NOT EXISTS SAA_OPERATIONS (
        OpId int PRIMARY KEY,
        OpName varchar(64) NOT NULL,
        OpDescr varchar(255),
        OpOwner varchar(64), 
        OpSubOperationTable varchar(255) NOT NULL, 
        OpSubOperationId varchar(255) NOT NULL, 
        OpFrequency int, 
	OpTos int,
        OpTimeout int 
        )";

#notes for Create_Operation variables =
#[saa.tables] i have decoupled a primary operation
#with a pointer to the specific sub-operation
#thus, the controlEnabled, sourcePort targetPort would be in the sub-op 
#a(of TcpConnect for example):
# because of this: sourcePort, targetPort, controlEnabled, adminOperation, 
# adminStrings and adminUrl as mentioned in the saa.tables would now be 
# handled in the respective sub-operation tables
#OpOwner varchar(64), #rttMonCtrlAdminOwner
#OpSubOperationTable varchar(255) NOT NULL, #e.g. SAA_IP_ECHO_SUBOP
#OpSubOperationId varchar(255) NOT NULL, # The Id within the OpSubOperationTable
#OpFrequency int, #rttMonCtrlAdminFrequency
#OpTimeout int #rttMonCtrlAdminTimeout

$Create_Collector = "CREATE TABLE IF NOT EXISTS SAA_COLLECTORS (
        CollId int PRIMARY KEY,
        CollName varchar(127) NOT NULL UNIQUE,
        CollDescr varchar(255),
        CollSrcId int NOT NULL,
        CollTgtId int NOT NULL, 
        CollOpId int NOT NULL, 
        CollStartTime int, 
        CollNvram int,
        CollLife int, 
        CollEndTime int,
        CollAdminIndex int 
        )";

#notes for Create_Collector:
#[seen in saa.tables]why do we need:
# RowAge, Owner here?
#CollSrcId int NOT NULL, #from SAA_SOURCES::SrcId
#CollTgtId int NOT NULL, #from SAA_TARGETS::TgtId
#CollOpId int NOT NULL, #from SAA_OPERATIONS::OpId
#CollStartTime int, #rttMonScheduleAdminRttStartTime
#CollNvram int,
#ColllLife int, #rttMonScheduleAdminRttLife
#CollEndTime int,
#CollAdminIndex int #entry for this collector in the SAA Agent

$Create_Ip_Echo_subop = "CREATE TABLE IF NOT EXISTS SAA_IP_ECHO_SUBOP (
        so_IpEchoId int PRIMARY KEY,
        so_IpEchoDataSize int, 
        so_IpEchoTos smallint,
        so_IpEchoLsrEnable smallint, 
        LsrHop0 varchar(127),
        LsrHop1 varchar(127),
        LsrHop2 varchar(127),
        LsrHop3 varchar(127),
        LsrHop4 varchar(127),
        LsrHop5 varchar(127),
        LsrHop6 varchar(127),
        LsrHop7 varchar(127)
        )";

#notes for Create_Ip_Echo_subop:
#so_IpEchoDataSize int, #rttMonEchoAdminPktDataRequestSize
#so_IpEchoTos smallint, #rttMonEchoAdminTOS
#so_IpEchoLsrEnable smallint, #rttMonEchoAdminLSREnable

$Create_User = "CREATE TABLE IF NOT EXISTS SAA_USERS (
		UserId			int PRIMARY KEY,
        Username        varchar(30),
        Firstname       varchar(30),
        Lastname        varchar(30),
        Password        varchar(50),
        Permissions     tinyint
)";

1;
