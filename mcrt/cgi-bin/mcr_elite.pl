#!/usr/local/bin/perl -w
#-------------------------------------------------------
# Script Name: mcr_elite.pl
# Version: 
# Last modified by: Weston Hopkins, April 2001. 
# Requirements: 
# Description: 	Gives statistics and distributions for a certain NAS.
# Created by: Weston Hopkins
# Date: April 2001
# Contact: coe-iae@cisco.com 
#-------------------------------------------------------

use DBI;
use DBD::mysql;
use CGI;

# - Variables and Setup --------------------------------
my $database = "deez";
my $db_hostname = "localhost";
my $tablename = "callrecs";
my $username = "";
my $password = "";
# - END Variable setup ---------------------------------

BEGIN {
	use CGI::Carp qw/carpout fatalsToBrowser/;
#	use FileHandle;
#	my $CGI_HANDLE = new FileHandle(">>/var/adm/cgi_error.log");
#	carpout($CGI_HANDLE);
}

$q = new CGI;

$devname  = $q->param('dev');
$year = $q->param('year');
$month = $q->param('month');
$day = $q->param('day');
$date = "$year-$month-$day";
my $devsql;
if( $devname ) {
	$devsql = " AND server=\"$devname\"";
} else {
	$devsql = "";
}

$db = DBI->connect("DBI:mysql:$database:$db_hostname" );
$sql = "SELECT snr, count(*) FROM $tablename GROUP BY snr;";

#@columns = qw/server dso_slot dso_contr dso_chan slot port call_id user_id ip calling called std prot comp init_rx init_tx
#rbs 
#dpad retr sq snr rx_chars tx_chars rx_ec tx_ec bad timeon final_state disc_radius disc_modem disc_local disc_remote
#timestamp/;

print $q->header();

print "<HTML>\n";
print "<TITLE> Daily Statistics for $devname </title>\n";
print " <H1> Statistics Today for $devname</h1>\n";
print " <H2> Averages </h2>\n";
# You would THINK the constraint should be WHERE DAYOFYEAR(date) = DAYOFYEAR(now()).. Don't do that.. Its like some
# O(n^10) runtime and some shit if you do it that way. 
printSQLTable( "SELECT avg(init_tx), avg(tx_chars), avg(snr), avg(retr), avg(timeon), avg(dpad), avg(bad) FROM $tablename WHERE date = '$date' $devsql;",
	$db,
	("TX Rate", "TX Characters", "SNR", "Retrains", "Time On", "Dial Pad", "Bad Frames") );
print " <H2> Maximums</h2>\n";
printSQLTable( "SELECT max(init_tx), max(tx_chars), max(snr), max(retr), max(timeon), max(dpad), max(bad) FROM $tablename WHERE date = '$date' $devsql;",
	$db,
	("TX Rate", "TX Characters", "SNR", "Retrains", "Time On", "Dial Pad", "Bad Frames") );

print " <TABLE VALIGN=top> \n";
print "  <TR ALIGN=center VALIGN=top>\n";

print "   <TD>\n";
print " <H2> SNR Distribution </h2>\n";
printSQLTable( "SELECT snr, count(*) FROM $tablename WHERE date = '$date' $devsql GROUP BY snr;", 
	$db, 
	("SNR", "Calls") );
print "  </td>\n";

print "   <TD>\n";
print " <H2> Connect TX Speed Distribution </h2>\n";
printSQLTable( "SELECT init_tx, count(*) from $tablename WHERE date = '$date' $devsql GROUP BY init_tx;",
	$db,
	("Connect TX Speed Distribution", "Calls" ) );
print "   </td>\n";

print "   <TD>\n";
print " <H2> Connection-Standard, Distribution </h2>\n";
printSQLTable( "SELECT std, count(*) FROM $tablename WHERE date = '$date' $devsql GROUP BY std;",
	$db,
	("Standard", "Calls" ) );
print "   </td>\n";

print "   <TD>\n";
print " <H2> Protocol Distribution </h2>\n";
printSQLTable( "SELECT prot, count(*) FROM $tablename WHERE date = '$date' $devsql GROUP BY prot;",
	$db,
	("Protocol", "Calls" ) );
print "   </td>\n";

print "   <TD>\n";
print " <H2> Disconnection Reason Distribution </h2>\n";
printSQLTable( "SELECT disc_modem, count(*) FROM $tablename WHERE date = '$date' $devsql GROUP BY disc_modem;",
	$db,
	("Disconnection Reason", "Calls" ) );
print "   </td>\n";
print "  </tr>\n";
print " </table>\n";

print " <TABLE VALIGN=top>\n";
print "  <TR ALIGN=center VALIGN=top>\n";
print "   <TD>\n";
print " <H2> Calls per server </h2>\n";
printSQLTable( "SELECT server, count(*) FROM $tablename WHERE date = '$date' $devsql GROUP BY server;",
	$db,
	("Server", "Count" ) );
print "   </td>\n";

#print "   <TD>\n";
#print " <H2> Calls by day </h2>\n";
#printSQLTable( "select DAYOFYEAR(timestamp), count(*) from $tablename group by DAYOFYEAR(timestamp);",
#	$db,
#	("Day of Year", "Calls" ) );
#print "   </td>\n";

print "   <TD>\n";
print " <H2> Calls by hour </h2>\n";
printSQLTable( "SELECT HOUR(timestamp), count(*) FROM $tablename WHERE date = '$date' $devsql GROUP BY HOUR(timestamp);",
	$db,
	("Hour", "Calls") );
print "   </td>\n";

print "</html>\n";
#..............................................................................
# printSQLTable( $sql, $db, @columns )
#... Print outs the results of an sql query in a tablular format using HTML
#... $sql: SQL statement to execute
#... $db: Reference to the database used as a source for the aforementioned SQL statement
#... @columns: The names of the columns to print out in the header of the table
#..............................................................................
sub printSQLTable {
	my( $sql, $db, @columns ) = @_;
	$sth = $db->prepare($sql);
	print(" <TABLE BGCOLOR=#FFFFFF NOWRAP border=1>\n");
	print("  <TR ALIGN=center>\n");
	foreach $column (@columns) {
		print("   <TD BGCOLOR=#550000><B><FONT COLOR=#FF0000 SIZE=+1>$column</font></b></td>\n" );
	}
	print("  </tr>\n");
	$sth->execute();
	
	$BG_COLOR="#FFFFFF";
	my $rowcount = 0;
	while( @row  = $sth->fetchrow_array ) {
		print(" <TR ALIGN=center BGCOLOR=$BG_COLOR>\n");
		$BG_COLOR = (($rowcount%2) == 0) ? "#FFCCCC" : "#FFFFFF";
		$rowcount++;
		$col = "";
		foreach $col (@row) {
			if( $col eq "" ) {
				$col = "NULL";
			}
			print( "   <TD>$col</td>\n" );
		}
		printf("  </tr>\n");
	}
	print(" </table>\n");
}
