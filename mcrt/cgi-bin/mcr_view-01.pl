#!/usr/local/bin/perl -w
#-------------------------------------------------------
# Script Name: mcr_view-01x.pl
# Version: 
# Last modified by: Weston Hopkins, April 2001
# Requirements: 
# Description: 	Inputs "nas names" & "logdate" submitted by logviewer html form.
#		Outputs MCR logs for specified NAS & date.
# Created by: Jim Leonard / Weston Hopkins
# Date: March 2001
# Contact: coe-iae@cisco.com 
#-------------------------------------------------------
# - Variables and Setup --------------------------------
use CGI;
use DBD::mysql;
use DBI;
use Time::CTime;
use Date::Parse;

$| = 1;

# - Variables and Setup --------------------------------
my $database = "mcrt";
my $db_hostname = "localhost";
my $tablename = "callrecs";
my $username = "nobody";
my $password = "ibm53tmi";
# - END Variable setup ---------------------------------

BEGIN
{
use CGI::Carp qw/carpout fatalsToBrowser/;
use FileHandle;
my $CGI_LOG = new FileHandle ( ">> /var/adm/cgi_error.log");
carpout($CGI_LOG);
}


# Edit $LWTCONF if neeeded to point to config folder.
#$LWTCONF = "/opt/CSCOlwt/conf";
$LWTCONF = "/root/mcrt/conf";

# Read default and over-ride variables...
# customizations should go into lwt.cfg.

do "$LWTCONF/lwt-defaults.cfg";
do "$LWTCONF/lwt.cfg";

my $q;
$q=new CGI;

# ------HTML Components-----------------

$pagespot = "/graphics/supportal_spot.jpg";
$pagebanner = "/graphics/mcrv_bn.gif";
$title = "MCR View #01";
$version = "1.69x";

print $q->header();	# start the html page for report
print template("$LWTHTML/lwt-start.lbi", {
    'title' => $title,
    'banner' => $pagebanner,
    'spot' => $pagespot,
    'version' => $version
});

# ---- Read CGI variables------

my $devname = $q->param('dev');	# get the dev name
my $month = $q->param('month');    	# get the month
my $day = $q->param('day');	# get the day o' month
my $year = $q->param('year');
my $date = "$year-$month-$day";

# ------ Prepare SQL Access and Connect-----------------
my $user = $username;
my $pwd = $password;
my $dsn = "dbi:mysql:$database;host=$db_hostname";
my $dbh = DBI->connect($dsn, $user, $pwd )
or die "Can't connect to mySQL database: $DBI::errstr\n";

@columns = qw/server dso_slot dso_contr dso_chan slot port call_id user_id ip calling called std prot comp init_rx init_tx rbs 
dpad retr sq snr rx_chars tx_chars rx_ec tx_ec bad timeon final_state disc_radius disc_modem disc_local
disc_remote start_time end_time timestamp/;

$sql = qq{SELECT * FROM $tablename where server = "$devname" AND start_time like "$date%" order by start_time};
print "<!--SQL: $sql-->\n";
$sth = $dbh->prepare($sql);
$sth->execute();

# Prints the header with the column names
print(" <TABLE BGCOLOR=#FFFFFF border=1>\n");
print("  <TR ALIGN=center>\n");
foreach $column (@columns) {
	print("   <TD BGCOLOR=#005500><B><FONT COLOR=#00FF00 SIZE=+1>$column</font></b></td>\n" );
}
print("  </tr>\n");

$rowcount = 0;
$BG_COLOR = "#FFFFFF";
# Prints the actual data
while( @row  = $sth->fetchrow_array ) {
	print(" <TR BGCOLOR=$BG_COLOR ALIGN=center>\n");
        $BG_COLOR = (($rowcount%2) == 0) ? "#CCFFCC" : "#FFFFFF";
        $rowcount++;
	my $col = "";
	my $i = 0;
	foreach $col (@row) {
		if( $col eq "" ) {
			$col = "NULL";
		} elsif ($i == 32 || $i == 33) {
			&frmat_date($row[$i]);
			$col = $p_date;
		}
		print( "   <TD NOWRAP>$col</td>\n" );
		$i++;
	}
	printf("  </tr></font>\n");
}
print "</table>\n";
1;
print "<BR><H2> $rowcount entries found.</h2>\n";
print template("$LWTHTML/lwt-end.lbi");
$sth->finish();
$dbh->disconnect();


################### SUBROUTINES #################################
# --- Subroutine: Print Template ----

sub template {
    my ($filename, $fillings) = @_;
    my $text;
    local $/;                   # slurp mode (undef)
    local *F;                   # create local filehandle
    open(F, "< $filename")      || return;
    $text = <F>;                # read whole file
    close(F);                   # ignore retval
    # replace quoted words with value in %$fillings hash
    $text =~ s{ %% ( .*? ) %% }
              { exists( $fillings->{$1} )
                      ? $fillings->{$1}
                      : ""
              }gsex;
    return $text;
}

sub frmat_date {

	(my $in_date) = @_;

	$in_date =~ s/\s/:/;
	
	$time = str2time($in_date); 
	
	$frmat = "%b %e, %Y %H:%M:%S";
	
	$p_date = strftime($frmat, localtime($time));
	
}
