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
#use strict;

# - Variables and Setup --------------------------------
my $database = "deez";
my $db_hostname = "localhost";
my $tablename = "callrecs";
my $username = "";
my $password = "";
# - END Variable setup ---------------------------------

BEGIN
{
	use CGI::Carp qw/carpout fatalsToBrowser/;
#	use FileHandle;
#	my $CGI_LOG = new FileHandle ( ">> /export/home/weston/cgi_error.log");
#	carpout($CGI_LOG);
}


# Edit $LWTCONF if neeeded to point to config folder.
$LWTCONF = "/opt/CSCOlwt/conf";

# Read default and over-ride variables...
# customizations should go into lwt.cfg.

do "$LWTCONF/lwt-defaults.cfg";
do "$LWTCONF/lwt.cfg";

my ($db, $sql, $q, $user_id, $ip, $sth, @row, $col) = '';
my $messages;
$db = DBI->connect("DBI:mysql:$database:$db_hostname" );
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

@columns = qw/server timestamp dso_slot dso_contr dso_chan slot port call_id calling called std prot comp init_rx init_tx rbs 
dpad retr sq snr rx_chars tx_chars rx_ec tx_ec bad timeon final_state disc_radius disc_modem disc_local disc_remote/;

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
	$sql = "\nSELECT $selector from $tablename where user_id = \"$user_id\";";
} elsif( $ip ) {
	if( $ip eq "allyourbase" ) {
	        print "\n<A HREF=\"http://www.xentao.com/allyourbase/ayb3.swf\">ALL YOUR BASE ARE BELONG TO US</a>";
	        exit;
	}
	$sql = "\nSELECT $selector from $tablename where ip = \"$ip\";";
} else {
	print( "<H4>IP and/or userid invalid.</h4>" );
	exit;
}

# Prepare the sql command	
$sth = $db->prepare($sql);
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
	foreach $col (@row) {
		if( $col eq "" ) {
			$col = "NULL";
		}
		print( "   <TD NOWRAP>$col</td>\n" );
	}
	printf("  </tr>\n");
}
print(" </table>\n");
print "<BR><H2> $rowcount entries found.</h2>\n";
print template("$LWTHTML/lwt-end.lbi");
$sth->finish();
$db->disconnect();

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
