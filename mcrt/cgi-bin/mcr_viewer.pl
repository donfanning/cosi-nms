#!/usr/local/bin/perl -w
#-------------------------------------------------------
# Script Name: mcr_viewer.pl
# Version: 
# Last modified by: Weston Hopkins, April 2001. 
# Requirements: 
# Description: 	Interface for running mcr_view-1, 2, mcr_elite, and others..
# Created by: Weston Hopkins / Jim Leonard
# Date: March 2001
# Contact: coe-iae@cisco.com 
#-------------------------------------------------------
# - Variables and Setup --------------------------------

use CGI;
BEGIN
{
use CGI::Carp qw/carpout fatalsToBrowser/;
use FileHandle;
my $CGI_LOG = new FileHandle ( ">> /var/adm/cgi_error.log");
carpout($CGI_LOG);
}

use Time::localtime;
$tm = localtime;

# Debug switch
$DEBUG = '';

# Edit $LWTCONF if neeeded to point to config folder.
$LWTCONF = "/opt/CSCOlwt/conf";

# Read default and over-ride variables...
# customizations should go into lwt.cfg.

do "$LWTCONF/lwt-defaults.cfg";
do "$LWTCONF/lwt.cfg";

# other intializations....

$q = new CGI;		# Create new CGI object

# ------HTML Components-----------------

$pagespot = "/graphics/supportal_spot.jpg";
$pagebanner = "/graphics/mcrv_bn.gif";
$title = "Modem Call Record Viewer";
$version = "1.69x";

# ------Start HTML --------------------------------------

print $q->header();	# start the html page for report
print template("$LWTHTML/lwt-start.lbi", {
    'title' => $title,
    'banner' => $pagebanner,
    'spot' => $pagespot,
    'version' => $version,
});

#Get dev names for select ----------------------------
my $log_dir = "$MCRDIR";
$DEVLISTFILE      = "$LWTCONFIG/devlist.dat";
my $devlist = "$DEVLISTFILE";
open(DEVFILE, "< $devlist");
my @devnames = <DEVFILE>;

#------------------------------------------------------
# Form 1 to get all mcr logs based on dev and timestamp
#------------------------------------------------------
print "<form METHOD=GET ACTION=/cgi-lwt/mcr_view-01x.pl>";
print "<b><font color='#3333FF'>Complete MCR Log Information:</font></b><table width='780' bgcolor='#d0d0d0' border='0'><tr><td>";
print "<b><font size=3>NAS: </font></b><select name=dev>";
for $dev(@devnames) {
	print "<OPTION>$dev";
}
print "</select> &nbsp; &nbsp;";
date_selector();
print "<tr><td><INPUT Type=submit Value='View LOG'></td></tr></table></form>";

#------------------------------------------------------------------------
# Form 2: Get user information
#-------------------------------------------------------------------------

print<<FORM2;
<form method='GET'
action=/cgi-lwt/mcr_view-02x.pl>
<b><font color='#3333FF'>Username Statistical Reports:</font></b>
<table BORDER=0 BGCOLOR='#d0d0d0' width='780'>
<tr>
<td><b><font color='#000000'>Username: </font></b>
<input type=TEXT name=user_id size=7>
 &nbsp; &nbsp; <i>or</i> &nbsp;
<b><font color='#000000'>IP address: </font></b>
<input type=TEXT name=ip size=15><br></td></tr>
FORM2

print<<FORM2B;
<tr>
<td>
<table BORDER=0 COLS=3 WIDTH="100%">

<tr>
<td><input type=CHECKBOX NAME=server VALUE='on' CHECKED>NAS
 <br><input type=CHECKBOX NAME=timestamp VALUE='on' CHECKED>Time Stamp
 <br><input type=CHECKBOX NAME=dso_slot VALUE='on'>DSO Slot
 <br><input type=CHECKBOX NAME=dso_contr VALUE='on'>DSO Control
 <br><input type=CHECKBOX NAME=dso_chan VALUE='on'>DSO Channel
 <br><input type=CHECKBOX NAME=slot VALUE='on'>Slot
 <br><input type=CHECKBOX NAME=port VALUE='on'>Port
 <br><input type=CHECKBOX NAME=call_id VALUE='on'>Call ID
 <br><input type=CHECKBOX NAME=calling VALUE='on'>Calling Number
 <br><input type=CHECKBOX NAME=called VALUE='on' CHECKED>Called Number
 <br><input type=CHECKBOX NAME=std VALUE='on' CHECKED>Connected Standard
</td>
<td><input type=CHECKBOX NAME=prot VALUE='on' CHECKED>Connect Protocol
 <br><input type=CHECKBOX NAME=comp VALUE='on' CHECKED>Compression
 <br><input type=CHECKBOX NAME=init_rx VALUE='on' CHECKED>Initial RX Bit Rate
 <br><input type=CHECKBOX NAME=init_tx VALUE='on' CHECKED>Initial TX Bit Rate
 <br><input type=CHECKBOX NAME=rbs VALUE='on'>RBS Pattern
 <br><input type=CHECKBOX NAME=dpad VALUE='on'>Digital Pad
 <br><input type=CHECKBOX NAME=retr VALUE='on' CHECKED>Retrains
 <br><input type=CHECKBOX NAME=sq VALUE='on'>Signal Quality
 <br><input type=CHECKBOX NAME=snr VALUE='on' CHECKED>Signal to Noise Ratio
 <br><input type=CHECKBOX NAME=rx_chars VALUE='on' CHECKED>RX Characters
</td>

<td><input type=CHECKBOX NAME=tx_chars VALUE='on' CHECKED>TX Characters
 <br><input type=CHECKBOX NAME=rx_ec VALUE='on' CHECKED>RX Error Correction Frames
 <br><input type=CHECKBOX NAME=tx_ec VALUE='on' CHECKED>TX Error Correction Frames
 <br><input type=CHECKBOX NAME=bad VALUE='on' CHECKED>Bad Characters
 <br><input type=CHECKBOX NAME=timeon VALUE='on' CHECKED>Time On
 <br><input type=CHECKBOX NAME=final_state VALUE='on' CHECKED>Final State
 <br><input type=CHECKBOX NAME=disc_radius VALUE='on'>Disconnect Reason (Radius)
 <br><input type=CHECKBOX NAME=disc_modem VALUE='on' CHECKED>Disconnect Reason (Modem)
 <br><input type=CHECKBOX NAME=disc_local VALUE='on'>Disconnect Reason (Local)
 <br><input type=CHECKBOX NAME=disc_remote VALUE='on'>Disconnect Reason (Remote)
</td>
</tr>
</table>
</td>
</tr>
<tr>
<td>
<input type='reset' value='Clear'>
<input type='submit' value='Submit'></td>
</tr>
</table>
</form>
FORM2B

### Daily Statistics (all servers)
print "<FORM METHOD=GET ACTION=/cgi-lwt/mcr_total_servers.pl>\n";
print " <B><FONT COLOR=#3333FF>Daily Statistics (all servers):</font></b>\n";
print " <TABLE WIDTH=780 BGCOLOR=#d0d0d0 BORDER=0>\n";
print " <TR>\n";
print "  <TD>\n";
date_selector();
print "  </td>\n";
print "  <TD><INPUT TYPE=SUBMIT VALUE=\"View stats\"></td>\n";
print "  </tr>\n";
print " </table>\n";
print "</form>\n";

### Daily Statistics
print "<FORM METHOD=GET ACTION=/cgi-lwt/mcr_elite.pl>\n";
print " <B><FONT COLOR='#3333FF'>Daily Statistics (per server):</font></b>\n";
print "  <TABLE WIDTH=780 BGCOLOR='#d0d0d0' BORDER=0>\n";
print "  <TR>\n";
print "   <TD> <b> <FONT SIZE=3>NAS: </font></b><select name=dev>";
for $dev(@devnames){
        print "      <OPTION>$dev\n";
}
print "    </select> &nbsp; &nbsp;\n";
print "  </td>\n";
print "  <TD>\n";
date_selector();
print "  </td>\n";
print "  <TD><INPUT TYPE=submit VALUE=\"View stats\"></td>\n";
print " </tr>\n";
print " </table>\n";
print "</form>\n";

#---------End HTML-----------------
print template("$LWTHTML/lwt-end.lbi");

#---------- Subroutines-------------

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

# date_selector()
### Prints out select boxes for the date. Defaults to current date.
sub date_selector {

	@months = qw( Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec );

	print "<b><font size=3>Month: </font></b>";
	print "<select name=month>\n";
	$i = 0;
	for $month(@months) {
		$i = $i+1;
		if( $i == ($tm->mon+1) ) {
			print "<OPTION SELECTED VALUE=$i> $month\n";
		} else {
			print "<OPTION VALUE=$i> $month\n";
		}
	}
	print "</select>&nbsp;&nbsp\n";

	print "<B><FONT SIZE=3>Day: </font></b>";
	print "<SELECT NAME=day>\n";
	for( $i=1; $i<=31; $i++ ) {
		if( $tm->mday == $i ) {
			print "<OPTION SELECTED> $i\n";
		} else {
			print "<OPTION> $i\n";
		}
	}
	print("</select>\n");

	print "<B><FONT SIZE=3>Year: </font></b>";
	print "<SELECT NAME=year>\n";
	for( $i=1999; $i<2005; $i++ ) {
		if( $tm->year+1900 == $i ) {
			print "<OPTION SELECTED VALUE=$i> $i\n";
		} else {
			print "<OPTION VALUE=$i> $i\n";
		}
	}
	print "</select><br>\n";
}
