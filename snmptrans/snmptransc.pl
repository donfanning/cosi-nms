#!/usr/bin/perl
#-
# Copyright (c) 2001 Joe Clarke <marcus@marcuscom.com>
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
# 1. Redistributions of source code must retain the above copyright
#    notice, this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright
#    notice, this list of conditions and the following disclaimer in the
#    documentation and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS'' AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
# OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
# HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
# LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
# OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
# SUCH DAMAGE.
#
# $Id$
#

BEGIN {
        $ENV{'PATH'} = '/bin:/usr/bin';
        delete @ENV{'IFS', 'CDPATH', 'ENV', 'BASH_ENV'};

        # This is the name of the script relative to the HTTP root.
        $ME = '/cgi-bin/snmptransc.pl';

        # This is is the server port to connect to for sending CGI parameters.
        $SERVER_PORT = 3333;

        # This is the address or IP address of the server.  By default, localhost
        # is used.
        $SERVER_ADDR = 'localhost';
}

use strict;
use IO::Socket;
use CGI;
use POSIX qw(tmpnam);
use vars
    qw($rcsid $SERVER_ADDR $SERVER_PORT $ME $q $cookie $client $data $result $size);
use constant MAX_FILE_SIZE => 1_048_576;
use constant BUFFER_SIZE   => 16_384;

$rcsid = '$Id$';

$| = 1;

$CGI::DISABLE_UPLOADS = 0;
$CGI::POST_MAX        = MAX_FILE_SIZE;

$q = new CGI;
$q->cgi_error
    and return_error("SNMP Translate Error", "Unable to parse CGI variables.");

if (defined($q->param('oid')) && $q->param('oid') eq "") {
        return_error("SNMP Translate Error",
                "You did not specify an object name or OID to translate.");
} elsif (defined($q->param('pattern')) && $q->param('pattern') eq "") {
        return_error("SNMP Search Error",
                "You did not specify a pattern for which to search.");
} elsif (defined($q->param('bulk_file')) && $q->param('bulk_file') eq "") {
        return_error("SNMP Bulk Translate Error",
                "You did not specify a source file to translate.");
}

# Make the user input ``oid'' string safe for Perl consumption.
# Don't escape everything since we need to allow for regular expressions.
my $oid = $q->param('oid');
$oid =~ s/([\~\`\&\;\"\<\>\'])//g;
$oid =~ s/\s//g;

if ($q->param('bg') eq "1") {
        return_error("Bad Regular Expression",
                "The regular expression <I>$oid</i> is not valid.")
            if (!(eval { 'snmp' =~ /$oid/i, 1 }));
}

$client = IO::Socket::INET->new(
        PeerPort => $SERVER_PORT,
        PeerAddr => $SERVER_ADDR,
        Type     => SOCK_STREAM,
        Proto    => 'tcp',
        Timeout  => 10
    )
    or return_error("Server Error", "Error communicating with server.");

my $results = "";

if (       defined($q->param('security'))
        || defined($q->cookie(-name => 'security')))
{

        my $security = "";
        if (defined($q->param('security'))) {
                $security = $q->param('security');
        } else {
                $security = $q->cookie(-name => 'security');
        }

        # Implement CHAP-like security
        use Digest::MD5 qw(md5_hex)
            ;    # This module is required for security to work.
        my $digest = md5_hex($security);
        send_data($client, "digest");
        $results = get_data($client);
        if ($results ne "403") {
                return_error(
                        "Server Error",
                        "Error initiating authentication with server (results = \"$results\")."
                );
        }
        send_data($client, $digest);
        $results = get_data($client);

        if ($results ne "200") {
                return_error(
                        "Server Error",
                        "Error authenticating with server (results = \"$results\")."
                );
        }

        # Use cookies to persist the security info.
        $cookie = $q->cookie(-name => "security", -value => $security);

        if (!defined($cookie)) {
                return_error(
                        "SNMP Translate Error",
                        "You do not have cookies enabled in your browser.  This application requires all cookies to be enabled."
                );
        }
}

if (defined($q->param('pattern'))) {
        my $pattern = $q->param('pattern');
        $pattern =~ s/([\~\`\&\;\"\<\>\'])/\\$1/g;

        send_data($client, "pattern");
        $results = get_data($client);
        if ($results ne "200") {
                return_error(
                        "Server Error",
                        "Error communicating with server (results = \"$results\")."
                );
        }
        send_data($client, "0");
        $results = get_data($client);

        if ($results ne "200") {
                return_error(
                        "Server Error",
                        "Error communicating with server (results = \"$results\")."
                );
        }
        send_data($client, "0");
        $results = get_data($client);

        if ($results ne "200") {
                return_error(
                        "Server Error",
                        "Error communicating with server (results = \"$results\")."
                );
        }

        send_data($client, $pattern);
        $results = get_data($client);

        if ($results ne "200") {
                return_error(
                        "Server Error",
                        "Error communicating with server (results = \"$results\")."
                );
        }
        send_data($client, $q->param('descr'));

        $results = get_data($client);
        if ($results eq "501") {
                return_error(
                        "Bad Regular Expression",
                        "The regular expression <I>"
                            . $q->param('pattern')
                            . "</i> is not valid."
                );
        } elsif ($results eq "404") {
                return_error(
                        "SNMP Search Error",
                        "No objects were found matching the pattern <I>"
                            . $q->param('pattern')
                            . "</i>.  Please alter your search pattern, and try again."
                );
        } elsif ($results eq "502") {
                return_error(
                        "SNMP Search Error",
                        "The server timed out before returning valid data.  Please try again with a more specific pattern."
                );
        } elsif ($results eq "500") {
                return_error("SNMP Search Error",
                        "Internal server error encountered.");
        }

        return_data($results);
        exit(0);
}

if (defined($q->param('bulk_file'))) {
        my $buffer  = "";
        my $fh      = $q->upload('bulk_file');
        my $command = '/usr/local/bin/walkres.pl';
        $results = "";

        if (defined($fh)) {
                my $tmp = "";

                while (read($fh, $tmp, BUFFER_SIZE)) {
                        $buffer .= $tmp;
                }
                undef $tmp;
        }

        close($fh);

        $buffer =~ s/\015$//;
        $buffer =~ s/\032$//;

        my $tmpfile = "";
        do { $tmpfile = tmpnam() } while (-f $tmpfile);

        open(TMP, ">" . $tmpfile)
            or return_error("File Error",
                "Error opening $tmpfile for writing: $!.");
        print TMP $buffer;
        close(TMP);

        my $i = 0;
        my $pid;

        if (!defined($pid = open(CMD, "-|"))) {
                unlink($tmpfile);
                return_error("Fork Error", "Failed to fork $command: $!");
        }

        if ($pid) {
                while (<CMD>) {
                        s/\&/&amp;/g;
                        s/\</&lt;/g;
                        s/\>/&gt;/g;
                        $results .= $_;
                }
                close(CMD);
        } else {
                if (!exec($command, $tmpfile)) {
                        unlink($tmpfile);
                        return_error("Exec Error",
                                "Failed to exec $command: $!");
                }
        }

        unlink($tmpfile);
        return_data($results);
        exit(0);
}

if ($q->param('xOps') eq "") {
        send_data($client, "simple");
        $results = get_data($client);
        if ($results ne "200") {
                return_error(
                        "Server Error",
                        "Error communicating with server (results = \"$results\")."
                );
        }
        send_data($client, "0") if ($q->param('bg') ne "1");
        send_data($client, "1") if ($q->param('bg') eq "1");
        $results = get_data($client);

        if ($results ne "200") {
                return_error(
                        "Server Error",
                        "Error communicating with server (results = \"$results\")."
                );
        }

        send_data($client, "0") if ($q->param('replace') ne "1");
        send_data($client, "1") if ($q->param('replace') eq "1");
        $results = get_data($client);

        if ($results ne "200") {
                return_error(
                        "Server Error",
                        "Error communicating with server (results = \"$results\")."
                );
        }

        send_data($client, $oid);
        $results = get_data($client);

        if ($results eq "404") {
                return_error(
                        "SNMP Translate Error",
                        "Unable to translate <I>$oid</i>.  The object was either not found or invalid."
                );
        } elsif ($results eq "502") {
                return_error(
                        "SNMP Translate Error",
                        "The server timed out before returning valid data.  Please try again with a more specific object."
                );
        } elsif ($results eq "500") {
                return_error("SNMP Search Error",
                        "Internal server error encountered.");
        }

        return_data($results);
} elsif ($q->param('xOps') eq "detail") {
        send_data($client, "detail");
        $results = get_data($client);
        if ($results ne "200") {
                return_error("Server Error",
                        "Error communicating with server.");
        }
        send_data($client, "0") if ($q->param('bg') ne "1");
        send_data($client, "1") if ($q->param('bg') eq "1");
        $results = get_data($client);

        if ($results ne "200") {
                return_error(
                        "Server Error",
                        "Error communicating with server (results = \"$results\")."
                );
        }

        send_data($client, "0") if ($q->param('replace') ne "1");
        send_data($client, "1") if ($q->param('replace') eq "1");
        $results = get_data($client);

        if ($results ne "200") {
                return_error(
                        "Server Error",
                        "Error communicating with server (results = \"$results\")."
                );
        }

        send_data($client, $oid);
        $results = get_data($client);

        if ($results eq "404") {
                return_error(
                        "SNMP Translate Error",
                        "Unable to translate <I>$oid</i>.  The object was either not found or invalid."
                );
        } elsif ($results eq "502") {
                return_error(
                        "SNMP Translate Error",
                        "The server timed out before returning valid data.  Please try again with a more specific object."
                );
        } elsif ($results eq "500") {
                return_error("SNMP Search Error",
                        "Internal server error encountered.");
        }

        return_data($results);
} elsif ($q->param('xOps') eq "tree") {
        send_data($client, "tree");
        $results = get_data($client);
        if ($results ne "200") {
                return_error("Server Error",
                        "Error communicating with server.");
        }
        send_data($client, "0") if ($q->param('bg') ne "1");
        send_data($client, "1") if ($q->param('bg') eq "1");
        $results = get_data($client);

        if ($results ne "200") {
                return_error(
                        "Server Error",
                        "Error communicating with server (results = \"$results\")."
                );
        }

        send_data($client, "0") if ($q->param('replace') ne "1");
        send_data($client, "1") if ($q->param('replace') eq "1");
        $results = get_data($client);

        if ($results ne "200") {
                return_error(
                        "Server Error",
                        "Error communicating with server (results = \"$results\")."
                );
        }

        send_data($client, $oid);
        $results = get_data($client);

        if ($results eq "404") {
                return_error(
                        "SNMP Translate Error",
                        "Unable to display tree for <I>$oid</i>.  The object was either not found or invalid."
                );
        } elsif ($results eq "502") {
                return_error(
                        "SNMP Translate Error",
                        "The server timed out before returning valid data.  Please try again with a more specific object."
                );
        } elsif ($results eq "500") {
                return_error("SNMP Search Error",
                        "Internal server error encountered.");
        }

        return_data($results);
}

$client->close();

sub return_error {
        my ($title, $message) = @_;

        print "Content-type: text/html", "\n\n";

        print <<ERROR;
<H1>$title</H1>
<HR>$message</HR>
ERROR
        $client->close() if ($client);
        exit(0);
}

sub send_data {
        my ($client, $data) = @_;
        my ($old_fh);

        $old_fh = select $client;
        $|      = 1;
        $data =~ s/\n/<br>/g;
        print $client $data . "\n";
        select $old_fh;
        $| = 1;
}

sub get_data {
        my ($client) = $_[0];
        my ($data);

        $data = <$client>;
        chop($data);
        $data =~ s/<br>/\n/g;
        return $data;
}

sub return_data {
        my ($data) = $_[0];

        print $q->header(-type => "text/html", -cookie => $cookie);
        print <<"EOH";
<head>
<title>SNMP Search &amp; Translate Results</title>
</head>
<body bgcolor="#FFFFFF">
<SCRIPT LANGUAGE="JavaScript">
<!-- //

function isBlank (s) {
        for (var i = 0; i < s.length; i++) {
                var c = s.charAt(i);
                if ((c != '') && (c != '\\n') && (c != '\\t')) return false;
        }
        return true;
}

function verifyTrans (f) {
	var oid = f.oid.value;

	if (isBlank(oid)) {
		alert("You must specify an object identifier or object name to translate.");
		return false;
	}

	return true;
}

function verifySearch (f) {
	var pattern = f.pattern.value;

	if (isBlank(pattern)) {
		alert("You must specify a search pattern.");
		return false;
	}

	return true;
}

// -->
</script>
EOH
        if (defined($q->param('oid'))) {
                print <<"EOH";

<H1>SNMP Translate</h1>

<P>
<TABLE BORDER="0">
<FORM NAME="snmptrans" METHOD="POST" ACTION="/cgi-bin/snmptransc.pl" onSubmit="
	return verifyTrans(this);
">
	<TR>
		<TD ALIGN="RIGHT"><B>Object Identifier or Object Name:</B> </TD>
		<TD ALIGN="LEFT"><INPUT TYPE="TEXT" NAME="oid"
		MAXLENGTH="120"></TD>
                <TD ALIGN="LEFT"><INPUT TYPE="CHECKBOX" NAME="bg" VALUE="1">
                <I>r.e.</I></TD>
<!--		<TD ALIGN="RIGHT"><INPUT TYPE="CHECKBOX" NAME="replace" VALUE="1">
		<I>replace</I></TD>-->

	</TR>
</TABLE>
<B><I>
<P>
	Translate Options
</P>
</I></B>
<TABLE BORDER="0">
	<TR>
		<TD><INPUT TYPE="RADIO" VALUE="" NAME="xOps">
		<B>Simple Translation
		<TD><INPUT TYPE="RADIO" VALUE="detail" NAME="xOps" CHECKED>
		<B>Detailed Translation</B></TD>
		<TD><INPUT TYPE="RADIO" VALUE="tree" NAME="xOps">
		<B>Tree Translation</B></TD>
	</TR>
</TABLE>
<P></p>
<TABLE BORDER="0">
	<TR ALIGN="CENTER">
		<TD ALIGN="LEFT"><INPUT TYPE="SUBMIT"
		NAME="action" VALUE="Translate"></TD>
		<TD ALIGN="RIGHT"><INPUT TYPE="RESET" VALUE="Cancel"></TD>
	</TR>
</TABLE>
</form>
EOH
        } else {
                print <<"EOH";
<H1>SNMP Search</h1>

<TABLE BORDER="0">
<FORM METHOD=POST ACTION="/cgi-bin/snmptransc.pl" NAME="snmpsearch" onSubmit="
	return verifySearch(this);
">
	<TR>
		<TD ALIGN="RIGHT"><B>Search Pattern:</b> </td>
		<TD ALIGN="LEFT"><INPUT TYPE="TEXT" NAME="pattern"
		MAXLENGTH="120"></td>
		<TD ALIGN="LEFT"><INPUT TYPE="CHECKBOX" NAME="descr" VALUE="1">
		<SMALL><I>Search description</I></SMALL></TD>
		
	</tr>
</table>
<P></p>
<TABLE BORDER="0">
	<TR ALIGN="CENTER">
		<TD ALIGN="RIGHT"><INPUT TYPE="SUBMIT" NAME="action"
		VALUE="Find Objects"></td>
		<TD ALIGN="LEFT"><INPUT TYPE="RESET" VALUE="Cancel"></td>
	</tr>
</table>
</form>
EOH
        }
        print <<"EOH";
<P>
</p>

<hr>

<h1>Results</h1>

$data

</body>
</html>
EOH
}

