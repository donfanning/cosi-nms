#!/usr/bin/perl
# script to create/reinit 'saaconf' database and the corresponding tables within the mysql subsystem

use strict;
use DBI;
use Getopt::Std;
use conf::prefs qw($DB_DRIVER $DB_USER $DB_PASS $DB_NAME);
use conf::tables
  qw($Create_Src $Create_Target $Create_Operation $Create_Collector $Create_User $Create_Ip_Echo_subop);
use vars qw (
  $sth
  $opt_h
  $opt_i
  $opt_r
);

getopts('hir');

sub help {
    print STDOUT <<EOF;
[init_db.pl] : script to create/reinitialize databasetables for saaconf
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

sub CreateDb {
    my ( $db_host, $user, $password, $db_name );

    #still trying to figure out how to create the database itself
    $db_host  = shift;
    $user     = shift;
    $password = shift;
    $db_name  = shift;

    #create the database here:
    #have to figure out a way to pass the create database query to msql subsys
    #http://www.mysql.com/doc/C/R/CREATE_DATABASE.html

    return 1;
}

sub ConnectDb {
    my $dbh =
      DBI->connect( 'dbi:' . $DB_DRIVER . ':' . $DB_NAME, $DB_USER, $DB_PASS )
      or die "SAA::DB: Unable to connect to database " . $DB_NAME;
    return $dbh;
}

sub AddTables {
    my $dbh = shift;

    #creating Source Table:
    #print "src: $Create_Src \n";
    die "init_db: $dbh->err()\n" if ( !( $sth = $dbh->prepare($Create_Src) ) );
    die "init_db: \$dbh->err()\n" if ( !( $sth->execute() ) );
    print "Source Table Creation SAA_SOURCES done\n";

    #creating Target Table:
    die "init_db: $$dbh->err() \n"
      if ( !( my $sth = $dbh->prepare($Create_Target) ) );
    die "init_db: $dbh->err() \n" if ( !( $sth->execute() ) );
    print "Target Table Creation SAA_TARGETS done\n";

    #creating Operation Table:
    #note: here the Operation Table would have info pointing to the sub-opertaion
    #e.g. Path Echo being run, with enough info to obtain/modify info in that 
    #sub-operation's table.
    die "init_db: $$dbh->err() \n"
      if ( !( $sth = $dbh->prepare($Create_Operation) ) );
    die "init_db: $$dbh->err() \n" if ( !( $sth->execute() ) );
    print "Operation Table Creation SAA_OPERATIONS done\n";

    #creating Collector Table:
    die "init_db: $$dbh->err() \n"
      if ( !( $sth = $dbh->prepare($Create_Collector) ) );
    die "init_db: $$dbh->err() \n" if ( !( $sth->execute() ) );
    print "Collector Table Creation SAA_COLLECTORS done\n";

    #creating User Table:
    die "init_db: $$dbh->err() \n"
      if ( !( $sth = $dbh->prepare($Create_User) ) );
    die "init_db: $$dbh->err() \n" if ( !( $sth->execute() ) );
    print "User Table Creation SAA_USERS done\n";

    #creating Ip Echo Sup Operation
    # note: I'm only creating ip echo for the time being...
    die "init_db: $$dbh->err() \n"
      if ( !( $sth = $dbh->prepare($Create_Ip_Echo_subop) ) );
    die "init_db: $$dbh->err() \n" if ( !( $sth->execute() ) );
    print "IpEchoOperation Table Creation SAA_IP_EHCO_SUBOP done\n";

}

sub DropTables {
    my $dbh = shift;

    #die "$!" if (!(my $sth = $dbh->prepare('show tables')));
    #die "$sth->err" if (!($sth->execute()));
    #die "$sth->err" if (!(my $array_ref = $sth->fetchall_arrayref));

    die "$dbh->err"
      if ( !( my $array_ref = $dbh->selectall_arrayref('show tables') ) );
    my $rowcount = scalar(@$array_ref);
    print "No tables in database: saaconf \n " if ( $rowcount == 0 );
    for ( my $i = 0 ; $i < $rowcount ; $i++ ) {
        print "dropping $array_ref->[$i][0]  ";
        my $tabledrop_statement = "DROP TABLE $array_ref->[$i][0] ";
        my $sth                 = $dbh->prepare($tabledrop_statement);
        die "$sth->err" if ( !( $sth->execute ) );
        print(".. dropped\n");
    }
}

sub KillConnect {
    my $dbh = shift;

    #$dbh->commit();
    $dbh->disconnect();
}

sub Init_Db {
    if ( &CreateDb( $DB_DRIVER, $DB_USER, $DB_PASS, $DB_NAME ) ) {
        my $dbh = &ConnectDb( $DB_DRIVER, $DB_USER, $DB_PASS, $DB_NAME );
        &AddTables($dbh);
        &KillConnect($dbh);
    }
}

sub ReInit_Db {
    if ( &CreateDb( $DB_DRIVER, $DB_USER, $DB_PASS, $DB_NAME ) ) {
        my $dbh = &ConnectDb( $DB_DRIVER, $DB_USER, $DB_PASS, $DB_NAME );
        &DropTables($dbh);
        &AddTables($dbh);
        &KillConnect($dbh);
    }
}

my $check_for_all = ( !( ($opt_i) | ($opt_h) | ($opt_r) ) );
&Init_Db()   if ($opt_i);
&help()      if ( ($opt_h) | ($check_for_all) );
&ReInit_Db() if ($opt_r);
