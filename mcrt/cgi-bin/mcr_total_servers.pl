#!/usr/bin/perl -w
# ......................oO mcr_total_servers.pl Oo.........
# .
# . Last modified by: Weston Hopkins, April 2001. 
# . Description: Does stats on all of the servers by each 
# . 	server so you can compare them side-by-side.
# . Created by: Weston Hopkins
# . Date: Apr 2001
# . Contact: coe-iae@cisco.com 
# ..........................................................

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

# ------ Prepare SQL Access and Connect-----------------
my $user = 'nobody';
my $pwd = "ibm53tmi";
#my $dsn = "dbi:mysql:feedback;host=sj-xxx-apps";
my $dsn = "dbi:mysql:mcrt;host=localhost";
my $dbh = DBI->connect($dsn, $user, $pwd )
or die "Can't connect to mySQL database: $DBI::errstr\n";

#$db = DBI->connect("DBI:mysql:$database:$db_hostname" );
#$sql = "SELECT snr, count(*) FROM $tablename GROUP BY snr;";
#$sql = "SELECT server, count(*) FROM $tablename GROUP BY server;";

# Gets the date that was passed with CGI
print $q->header();
$year = $q->param('year');
$month = $q->param('month');
$day = $q->param('day');
$date = "$year-$month-$day";


print "<HTML>\n";
print "<TITLE> Daily Statistics NAS comparison</title>\n";
print " <H2> Averages </h2>\n";
# You would THINK the constraint should be WHERE DAYOFYEAR(date) 
# = DAYOFYEAR(now()).. Don't do that.. Its like 
# O(n^10) runtime and some shit if you do it that way. 
#printSQLTable( "SELECT server, avg(init_tx), avg(tx_chars), avg(init_rx), avg(rx_chars), avg(snr), avg(retr), avg(timeon), avg(dpad), avg(bad) FROM $tablename WHERE date = '$date' group by server;",
printSQLTable(qq{SELECT server, avg(init_tx), avg(tx_chars), avg(init_rx), avg(rx_chars), avg(snr), avg(retr), avg(timeon), avg(dpad), avg(bad) FROM $tablename WHERE start_time like "$date%" group by server},
	$dbh,
	("NAS", "TX Rate", "TX Characters", "RX Rate", "RX Characters", "SNR", "Retrains", "Time On", "Dial Pad", "Bad Frames") );
print " <H2> Maximums</h2>\n";
printSQLTable(qq{SELECT server, max(init_tx), max(tx_chars), max(init_rx), max(rx_chars), max(snr), max(retr), max(timeon), max(dpad), max(bad) FROM $tablename WHERE start_time like '$date%' group by server},
	$dbh,
	( "NAS", "TX Rate", "TX Characters", "RX Rate", "RX Characters", "SNR", "Retrains", "Time On", "Dial Pad", "Bad Frames") );

print " <TABLE VALIGN=top> \n";
print "  <TR ALIGN=center VALIGN=top>\n";

print " <TABLE VALIGN=top>\n";
print "  <TR ALIGN=center VALIGN=top>\n";
print "   <TD>\n";
print "   <H2> Calls per server </h2>\n";
printSQLTable( "SELECT server, count(*) FROM $tablename WHERE date = '$date' $devsql GROUP BY server;",
	$dbh,
	("Server", "Count" ) );
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
	$sth = $dbh->prepare($sql);
	print(" <TABLE BGCOLOR=#FFFFFF border=1>\n");
	print("  <TR ALIGN=center>\n");
	# Prints the header with the column names
	foreach $column (@columns) {
		print("   <TD BGCOLOR=#005500><B><FONT COLOR=#00FF00 SIZE=+1>$column</font></b></td>\n" );
	}
	print("  </tr>\n");
	$sth->execute();
	
	# Prints the actual data
	$BG_COLOR="#FFFFFF";
	my $rowcount = 0;
	while( @row  = $sth->fetchrow_array ) {
		print(" <TR ALIGN=center BGCOLOR=$BG_COLOR>\n");
		$BG_COLOR = (($rowcount%2) == 0) ? "#CCFFCC" : "#FFFFFF"; # Alternate between the row colors
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
