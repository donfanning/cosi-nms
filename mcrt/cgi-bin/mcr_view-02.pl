#!/usr/local/bin/perl -w
#-------------------------------------------------------
# Script Name: mcr_view-02x.pl
# Version: 
# Last modified by: Weston Hopkins, 3 Apr 2001
# Requirements: 
# Description: 	Given a "username", or an 'ip_address' this script pulls
# out the variables of interest from the input data (modem  call records)
# for that particular 'username' or 'ip_address' and report them
# without any formatting.
# Created by: M. Saifur Rahman / Jim Leonard / Weston Hopkins
# Date: April, 2000
# Contact: coe-iae@cisco.com 
#-------------------------------------------------------
use CGI;
use DBD::mysql;
use DBI;
use Time::CTime;
use Date::Parse;


#use strict;

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
#	my $CGI_LOG = new FileHandle ( ">> /export/home/weston/cgi_error.log");
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

my ($dbh, $sql, $q, $user_id, $ip, $sth, @row, $col) = '';
my $messages;
# ------ Prepare SQL Access and Connect-----------------
my $user = 'nobody';
my $pwd = "ibm53tmi";
#my $dsn = "dbi:mysql:feedback;host=sj-xxx-apps";
my $dsn = "dbi:mysql:$database;host=$db_hostname";
$dbh = DBI->connect($dsn, $user, $pwd )
or die "Can't connect to mySQL database: $DBI::errstr\n";

$q = new CGI;

# ------HTML Components-----------------
$pagespot = "/graphics/supportal_spot.jpg";
$pagebanner = "/graphics/mcrv_bn.gif";
$title = "MCR View #02";
$version = "1.69x";

print $q->header();
print template("$LWTHTML/lwt-start.lbi", {
    'title' => $title,
    'banner' => $pagebanner,
    'spot' => $pagespot,
    'version' => $version
});


$user_id = $q->param('user_id');
$ip = $q->param('ip');

@columns = qw/server  start_time end_time dso_slot dso_contr dso_chan 
slot port call_id calling called std prot comp init_rx init_tx rbs 
dpad retr sq snr rx_chars tx_chars rx_ec tx_ec bad timeon final_state 
disc_radius disc_modem disc_local disc_remote/;

my @selections;
my $selector = "user_id, ip";
push( @selections, "user_id" );
push( @selections, "ip" );

foreach $column (@columns) {
	if( $q->param("$column") ) {
		push( @selections, "$column" );
		$selector .= ", $column";
	}
}
if( $user_id ) {
	$sql = qq{SELECT $selector from $tablename where user_id = "$user_id" order by start_time};
} elsif( $ip ) {
	$sql = qq{\nSELECT $selector from $tablename where ip = "$ip" order by start_time};
} else {
	print( "<H4>IP and/or userid invalid.</h4>" );
	exit;
}

1;

# Prepare the sql command	
$sth = $dbh->prepare($sql);
$sth->execute();
print "<!-- SQL: $sql -->\n";
print(" <TABLE BGCOLOR=#FFFFFF border=1>\n");

print("  <TR ALIGN=center>\n");
foreach $column (@selections) {
	print("   <TD BGCOLOR=#003300><B><FONT COLOR=#00FF00 SIZE=+1>$column</font></b></td>\n" );
}
print("  </tr>\n");

$BG_COLOR="#FFFFFF";
my $rowcount = 0;
while( @row  = $sth->fetchrow_array ) {
	print(" <TR ALIGN=center BGCOLOR=$BG_COLOR>\n");
	$BG_COLOR = (($rowcount%2) == 0) ? "#00FFAA" : "#FFFFFF";
	$rowcount++;
	$col = "";
	my $j = 0;
	foreach $col (@row) {
		if( $col eq "" ) {
			$col = "NULL";
		} elsif(("$selections[$j]" eq "start_time") || 
		("$selections[$j]" eq "end_time")) {
			&frmat_date($row[$j]);
			$row[$j] = $p_date;
		}
		print( "   <TD NOWRAP>$col</td>\n" );
		$j++
	}
	printf("  </tr>\n");
}
print(" </table>\n");
print "<BR><H2> $rowcount entries found.</h2>\n";
print template("$LWTHTML/lwt-end.lbi");
$sth->finish();
$dbh->disconnect();

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
