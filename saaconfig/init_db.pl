#!/usr/bin/perl
# script to create/reinit 'saaconf' database and the corresponding tables within the mysql subsystem

#use strict;
use DBI;
use Getopt::Std;
getopt("hir");
use conf::prefs qw($DB_DRIVER $DB_USER $DB_PASS $DB_NAME);


sub help {
	print STDOUT <<EOF;
reinit.pl : script to create/reinitialize databasetables for saaconf
syntax:
reinit.pl [-h] [-i|-r]
Options:
	-i:		Initialize the database and create tables
			[needs to be run prior to using saaconfig tool
	-r:		Reinitialize (drop/readd) the tables for a fresh db
	-h help:	Help (this window)
EOF
exit;
	}


sub CreateDb	{
	my ($db_host, $user, $password, $db_name);
	#still trying to figure out how to create the database itself
	$db_host = shift;
	$user = shift;
	$password = shift;
	$db_name = shift;

 	#create the database here:
	#have to figure out a way to pass the create database query to msql subsys
	#http://www.mysql.com/doc/C/R/CREATE_DATABASE.html

	return 1
		}

sub ConnectDb	{
	my $dbh = DBI->connect( 'dbi:' . $DB_DRIVER . ':' . $DB_NAME, $DB_USER, $DB_PASS )
      or die "SAA::DB: Unable to connect to database " . $DB_NAME;
	return $dbh;
		}
	
sub AddTables	{
	my $dbh = shift;
	###################
	#creating Source Table:
	my $create_src = "CREATE TABLE IF NOT EXISTS SAA_SOURCES (
	SrcId int PRIMARY KEY,
	SrcAlias varchar(64) NOT NULL UNIQUE, 
	SrcIpAddr varchar(127) NOT NULL UNIQUE, 
	SrcDescr varchar(255),
	SrcHostName varchar(64), 
	SrcReadComm varchar(32),
	SrcWriteComm varchar(32),
	SrcIosVersion varchar(64),
	SrcRttAppVersion varchar(64)
	)";
	die "init_db: $dbh->err()\n"	if (!(my $sth = $dbh->prepare($create_src)));
	die "init_db: \$dbh->err()\n"	if (!($sth->execute()));
	print "Source Table Creation SAA_SOURCES done\n";

	###################
	#creating Target Table:
	my $create_target = "CREATE TABLE IF NOT EXISTS SAA_TARGETS (
	TgtId int PRIMARY KEY,
	TgtAlias varchar(64) NOT NULL UNIQUE,
	TgtIpAddr varchar(127) NOT NULL UNIQUE,
	TgtDescr varchar(255),
	TgtHostName varchar (64),
	TgtReadComm varchar (32),
	TgtIosVersion varchar (64),
	TgtRttAppVersion varchar (64)
	)";
	die "init_db: $$dbh->err() \n" if (!(my $sth = $dbh->prepare($create_target)));
	die "init_db: $dbh->err() \n" if (!($sth->execute()));
	print "Target Table Creation SAA_TARGETS done\n";

	###################
	#creating Operation Table:
	#note: here the Operation Table would have info pointing to the sub-opertaion
	#e.g. Path Echo being run, with enough info to obtain/modify info in that 
	#sub-operation's table.
	my $create_operation = "CREATE TABLE IF NOT EXISTS SAA_OPERATIONS (
	OpId int PRIMARY KEY,
	OpName varchar(64) NOT NULL,
	OpDescr varchar(255),
	OpOwner varchar(64), #rttMonCtrlAdminOwner
	OpSubOperationTable varchar(255) NOT NULL, #e.g. SAA_IP_ECHO_SUBOP
	OpSubOperationId varchar(255) NOT NULL, # The Id within the OpSubOperationTable
	OpFrequency int, #rttMonCtrlAdminFrequency
	OpTimeout int #rttMonCtrlAdminTimeout
	)";

	die "init_db: $$dbh->err() \n" if (!(my $sth = $dbh->prepare($create_operation)));
        die "init_db: $$dbh->err() \n" if (!($sth->execute()));
        print "Operation Table Creation SAA_OPERATIONS done\n";
	
	
	###################
	#creating Collector Table:
	my $create_coll = "CREATE TABLE IF NOT EXISTS SAA_COLLECTORS (
	CollId int PRIMARY KEY,
 	CollName varchar(127) NOT NULL UNIQUE,
	CollDescr varchar(255),
	CollSrcId int NOT NULL, #from SAA_SOURCES::SrcId
	CollTgtId int NOT NULL, #from SAA_TARGETS::TgtId
	CollOpId int NOT NULL, #from SAA_OPERATIONS::OpId
	CollStartTime int, #rttMonScheduleAdminRttStartTime
	CollDuration int, #rttMonScheduleAdminRttLife
	CollEndTime int,
	CollAdminIndex int #entry for this collector in the SAA Agent
	)";	
        die "init_db: $$dbh->err() \n" if (!(my $sth = $dbh->prepare($create_coll)))
;
        die "init_db: $$dbh->err() \n" if (!($sth->execute()));
        print "Collector Table Creation SAA_COLLECTORS done\n";
 
	
	####################
	#creating Ip Echo Sup Operation
	# note: I'm only creating ip echo for the time being...
	my $create_ip_echo = "CREATE TABLE IF NOT EXISTS SAA_IP_ECHO_SUBOP (
	so_IpEchoId int PRIMARY KEY,
	so_IpEchoDataSize int, #rttMonEchoAdminPktDataRequestSize	
	so_IpEchoTos smallint, #rttMonEchoAdminTOS
	so_IpEchoLsrEnable smallint, #rttMonEchoAdminLSREnable
	LsrHop0 varchar(127),
	LsrHop1 varchar(127),
	LsrHop2 varchar(127),
	LsrHop3 varchar(127),
	LsrHop4 varchar(127),
	LsrHop5 varchar(127),
	LsrHop6 varchar(127),
	LsrHop7 varchar(127)
 	)";
	die "init_db: $$dbh->err() \n" if (!(my $sth = $dbh->prepare($create_ip_echo)))
;      
        die "init_db: $$dbh->err() \n" if (!($sth->execute()));
        print "IpEchoOperation Table Creation SAA_IP_EHCO_SUBOP done\n";
	
	}

sub DropTables	{
	my $dbh = shift;
	die "$!" if (!(my $sth = $dbh->prepare('show tables')));
	die "$sth->err" if (!($sth->execute()));
	die "$sth->err" if (!(my $array_ref = $sth->fetchall_arrayref));
	my @tables = @$array_ref;
	my $table;
	foreach $table (@tables)	{
		chomp $table;
		print "dropping $table..";
		$tabledrop_statement = "drop $table";
		$sth = $dbh->prepare($tabledrop_statement);
		die "$sth->err" if (!($sth->execute));
		print ("dropped\n");	
					}
		}	

sub KillConnect	{
	my $dbh = shift;
	#$dbh->commit();
	$dbh->disconnect();
		}
	
sub Init_Db	{
	if (&CreateDb($DB_HOST,$DB_USER,$DB_PASS,$DB_NAME)) {
	my $dbh = &ConnectDb($DB_HOST,$DB_USER,$DB_PASS,$DB_NAME);
	&AddTables($dbh);
	&KillConnect($dbh);
							}
		}

sub ReInit_Db	{
	if (&CreateDb($DB_HOST,$DB_USER,$DB_PASS,$DB_NAME)) {
	my $dbh = &ConnectDb($DB_HOST,$DB_USER,$DB_PASS,$DB_NAME);
	&DropTables($dbh);
	&AddTables($dbh);
	&KillConnect($dbh);
							}
		}



&Init_Db();
#if ($opt_i) { 	&Init_Db() };
#if ($opt_h) {	&help() };
