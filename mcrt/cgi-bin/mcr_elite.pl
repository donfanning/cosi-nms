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
my $database = "mcrt";
my $db_hostname = "localhost";
my $tablename = "callrecs";
my $username = "nobody";
my $password = "ibm53tmi";
# - END Variable setup ---------------------------------

BEGIN {
	use CGI::Carp qw/carpout fatalsToBrowser/;
	use FileHandle;
	my $CGI_HANDLE = new FileHandle(">>/var/adm/cgi_error.log");
	carpout($CGI_HANDLE);
}

$q = new CGI;

$devname  = $q->param('dev');
$year = $q->param('year');
$month = $q->param('month');
$day = $q->param('day');
$date = "$year-$month-$day";
#$date = "$year$month$day";
my $devsql;
if( $devname ) {
	$devsql = " AND server=\"$devname\"";
} else {
	$devsql = "";
}

# ------ Prepare SQL Access and Connect-----------------
my $user = 'nobody';
my $pwd = "ibm53tmi";
#my $dsn = "dbi:mysql:feedback;host=sj-xxx-apps";
my $dsn = "dbi:mysql:mcrt;host=localhost";
my $dbh = DBI->connect($dsn, $user, $pwd )
or die "Can't connect to mySQL database: $DBI::errstr\n";


#$dbh = DBI->connect("DBI:mysql:$database:$db_hostname" );
#$sql = "SELECT snr, count(*) FROM $tablename GROUP BY snr;";

#@columns = qw/server dso_slot dso_contr dso_chan slot port call_id user_id ip calling called std prot comp init_rx init_tx
#rbs 
#dpad retr sq snr rx_chars tx_chars rx_ec tx_ec bad timeon final_state disc_radius disc_modem disc_local disc_remote
#timestamp/;

print $q->header();

print "<HTML>\n";
print "<TITLE> Daily Statistics for $devname </title>\n";
print " <H1> Statistics Today for $devname</h1>\n";
print " <H2> Averages </h2>\n";
# You would THINK the constraint should be WHERE DAYOFYEAR(date) = DAYOFYEAR(now()).. 
# Don't do that.. Its like some
# O(n^10) runtime and some shit if you do it that way. 
printSQLTable( qq(SELECT avg(init_tx), avg(tx_chars), avg(snr), avg(retr), avg(timeon), avg(dpad), avg(bad) FROM $tablename WHERE start_time like "$date%" $devsql),
	$dbh,
	("TX Rate", "TX Characters", "SNR", "Retrains", "Time On", "Dial Pad", "Bad Frames") );
print " <H2> Maximums</h2>\n";
printSQLTable( qq(SELECT max(init_tx), max(tx_chars), max(snr), max(retr), max(timeon), max(dpad), max(bad) FROM $tablename WHERE start_time like "$date%" $devsql),
	$dbh,
	("TX Rate", "TX Characters", "SNR", "Retrains", "Time On", "Dial Pad", "Bad Frames") );

print " <TABLE VALIGN=top> \n";
print "  <TR ALIGN=center VALIGN=top>\n";

print "   <TD>\n";
print " <H2> SNR Distribution </h2>\n";
printSQLTable( qq(SELECT count(*) FROM $tablename WHERE start_time like "$date%" $devsql GROUP BY start_time), 
	$dbh, 
	("SNR", "Calls") );
print "  </td>\n";

print "   <TD>\n";
print " <H2> Connect TX Speed Distribution </h2>\n";
printSQLTable( qq(SELECT init_tx, count(*) from $tablename WHERE start_time like "$date%" $devsql GROUP BY init_tx),
	$dbh,
	("Connect TX Speed Distribution", "Calls" ) );
print "   </td>\n";

print "   <TD>\n";
print " <H2> Connection-Standard, Distribution </h2>\n";
printSQLTable( qq(SELECT std, count(*) FROM $tablename WHERE start_time like "$date%" $devsql GROUP BY std),
	$dbh,
	("Standard", "Calls" ) );
print "   </td>\n";

print "   <TD>\n";
print " <H2> Protocol Distribution </h2>\n";
printSQLTable( qq(SELECT prot, count(*) FROM $tablename WHERE start_time like "$date%" $devsql GROUP BY prot),
	$dbh,
	("Protocol", "Calls" ) );
print "   </td>\n";

print "   <TD>\n";
print " <H2> Disconnection Reason Distribution </h2>\n";
printSQLTable( qq(SELECT disc_modem, count(*) FROM $tablename WHERE start_time like "$date%" $devsql GROUP BY disc_modem),
	$dbh,
	("Disconnection Reason", "Calls" ) );
print "   </td>\n";
print "  </tr>\n";
print " </table>\n";

print " <TABLE VALIGN=top>\n";
print "  <TR ALIGN=center VALIGN=top>\n";
print "   <TD>\n";
print " <H2> Calls per server </h2>\n";
printSQLTable( qq(SELECT server, count(*) FROM $tablename WHERE date = '$date' $devsql GROUP BY server),
	$dbh,
	("Server", "Count" ) );
print "   </td>\n";

#print "   <TD>\n";
#print " <H2> Calls by day </h2>\n";
#printSQLTable( "select DAYOFYEAR(start_time), count(*) from $tablename group by DAYOFYEAR(start_time);",
#	$dbh,
#	("Day of Year", "Calls" ) );
#print "   </td>\n";

print "   <TD>\n";
print " <H2> Calls by hour </h2>\n";
printSQLTable( qq(SELECT HOUR(start_time), count(*) FROM $tablename WHERE start_time like "$date%" $devsql GROUP BY HOUR(start_time)),
	$dbh,
	("Hour", "Calls") );
print "   </td>\n";

print "</html>\n";
#..............................................................................
# printSQLTable( $sql, $dbh, @columns )
#... Print outs the results of an sql query in a tablular format using HTML
#... $sql: SQL statement to execute
#... $dbh: Reference to the database used as a source for the aforementioned SQL statement
#... @columns: The names of the columns to print out in the header of the table
#..............................................................................
sub printSQLTable {
	my( $sql, $dbh, @columns ) = @_;
	print(" <TABLE BGCOLOR=#FFFFFF NOWRAP border=1>\n");
	print("  <TR ALIGN=center>\n");
	foreach $column (@columns) {
		print("   <TD BGCOLOR=#550000><B><FONT COLOR=#FF0000 SIZE=+1>$column</font></b></td>\n" );
	}
	print("  </tr>\n");
	$sth = $dbh->prepare($sql);
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
