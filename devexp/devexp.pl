#!/opt/CSCOpx/bin/perl
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

use LWP::UserAgent;
use MIME::Base64;
use strict;

use vars qw($VERSION $CONF_FILE %PREFS $URL $DEVSERVLET $XMLFILE);

sub LOCK_SH { 1 }
sub LOCK_EX { 2 }
sub LOCK_NB { 4 }
sub LOCK_UN { 8 }

$VERSION    = '1.4';
$DEVSERVLET = '/CSCOnm/servlet/com.cisco.nm.cmf.servlet.DeviceListService';

if ($^O eq "MSWin32") {
        use CRM;
        $CONF_FILE = $ENV{'NMSROOT'} . "\\objects\\devexp\\devexp.conf";
        $XMLFILE   = $ENV{'NMSROOT'} . "\\objects\\devexp\\devexp.xml";
} else {
        $CONF_FILE = "/opt/CSCOpx/objects/devexp/devexp.conf";
        $XMLFILE   = "/opt/CSCOpx/objects/devexp/devexp.xml";
}

local *CONF;
unless (open(CONF, $CONF_FILE)) {
        die "Unable to open $CONF_FILE: $!\n";
}
flock(CONF, LOCK_SH);

while (<CONF>) {
        chomp;
        s/#.*//;
        s/^\s+//;
        s/\s+$//;
        next unless length;
        my ($name, $value) = split (/\s*=\s*/, $_, 2);
        $PREFS{$name} = $value;
}
close(CONF);

### The password needs to be Base64 encoded.
$PREFS{'ADMIN_PASSWD'} = encode_base64($PREFS{'ADMIN_PASSWD'});

### Take off the '\n' at the end of the encoded password.
chomp($PREFS{'ADMIN_PASSWD'});

local *XML;
unless (open(XML, $XMLFILE)) {
        die "Unable to open file $XMLFILE: $!\n";
}
flock(XML, LOCK_SH);

my $xmlpacket = "";
while (<XML>) {
        s/\%\%TYPE\%\%/$PREFS{'OUTPUT_FORMAT'}/;
        s/\%\%PASSWD\%\%/$PREFS{'ADMIN_PASSWD'}/;
        s/\%\%HOST\%\%/$PREFS{'RME_SERVER'}/;
        s/\%\%PROD\%\%/DevExp/;
        s/\%\%VERS\%\%/$VERSION/;
        s{ \%\%OP\%\% }
	   { ($PREFS{'OUTPUT_DEVICE_CREDENTIALS'} =~ /yes/i)
	         ? "<getDeviceCredentials/>"
		 : "<listDevices deviceType=\"\%\%DEVS\%\%\"/>"
	}ex;
        s/\%\%DEVS\%\%/$PREFS{'DEVICES'}/;
        s{ \%\%DTDPATH\%\% }
		{ ($PREFS{'DTD_PATH'} eq "")
			? "$PREFS{'RME_SERVER'}:$PREFS{'RME_PORT'}\/devexp\/devexp.dtd"
		  : $PREFS{'DTD_PATH'}
	}ex;

        $xmlpacket .= $_;
}
close(XML);

$URL =
    $PREFS{'RME_PROTOCOL'} . '://'
    . $PREFS{'RME_SERVER'} . ':'
    . $PREFS{'RME_PORT'}
    . $DEVSERVLET;

my $ua = new LWP::UserAgent;
$ua->agent("DevExp/$VERSION " . $ua->agent);

# Set a timeout of 30 minutes for users with large databases.
$ua->timeout(1800);

### Create a request
my $request = new HTTP::Request POST => $URL;
$request->content_type('application/x-www-form-urlencoded');
$request->content($xmlpacket);

my $response = $ua->request($request);

### Check the outcome of the response
if ($response->is_success) {
        local *OUTFILE;
        unless (open(OUTFILE, ">" . $PREFS{'OUTPUT_FILE'})) {
                die "Unable to open $PREFS{'OUTPUT_FILE'}: $!\n";
        }
        flock(OUTFILE, LOCK_EX);
        my $old_fh = select(OUTFILE);
        $| = 1;

        print $response->content;

        select($old_fh);
        close(OUTFILE);
} else {
        die
            "The request failed.  Please check the config file\nto make sure all the options are correct.\n";
}

exit(0);
