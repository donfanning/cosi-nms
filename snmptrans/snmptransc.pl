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
use vars
 qw($rcsid $SERVER_ADDR $SERVER_PORT $ME %contents $client $data $result $size);

$rcsid = '$Id$';

$| = 1;

# Insure POST method
if ( $ENV{'REQUEST_METHOD'} eq 'POST' ) {

    # Count the bytes received
    my $buffer;
    read( STDIN, $buffer, $ENV{'CONTENT_LENGTH'} );

    # make list of name/value pairs
    my @pairs = split ( /&/, $buffer );
    my $pair;

    # cycle through each pair and parse
    foreach $pair (@pairs) {

        # get the name/value pair
        my ( $name, $value ) = split ( /=/, $pair );

        # translate "+" to white space
        $value =~ tr/+/ /;

        # translate ASCII hex escaped characters if any
        $value =~ s/%([a-fA-F0-9][a-fA-F0-9])/pack("C", hex($1))/eg;

        # add the pair to a list marked on the name of the variable
        if ( defined( $contents{$name} ) ) {
            $contents{$name} = join ( "\0", $contents{$name}, $value );
        }
        else {
            $contents{$name} = $value;
        }
    }
}
elsif ( $ENV{'REQUEST_METHOD'} eq 'GET' ) {    # Do the same thing for GET.
    my @pairs = split ( /&/, $ENV{'QUERY_STRING'} );
    my $pair;

    foreach $pair (@pairs) {
        $pair =~ tr/+/ /;
        $pair =~ s/%([a-fA-F0-9][a-fA-F-0-9])/pack("C",hex($1))/eg;
        my ( $name, $value ) = split ( /=/, $pair );
        $value = 1 if ( !defined($value) );
        $contents{$name} = $value;
    }
}

if ( defined( $contents{'oid'} ) && $contents{'oid'} eq "" ) {
    return_error( "SNMP Translate Error",
      "You did not specify an object name or OID to translate." );
}
elsif ( defined( $contents{'pattern'} ) && $contents{'pattern'} eq "" ) {
    return_error( "SNMP Search Error",
      "You did not specify a pattern for which to search." );
}

# Make the user input ``oid'' string safe for Perl consumption.
# Don't escape everything since we need to allow for regular expressions.
$contents{'oid'} =~ s/([\~\`\&\;\"\<\>\'])//g;
$contents{'oid'} =~ s/\s//g;

if ( $contents{'bg'} eq "1" ) {
    return_error( "Bad Regular Expression",
      "The regular expression <I>$contents{'oid'}</i> is not valid." )
      if ( !( eval { 'snmp' =~ /$contents{'oid'}/i, 1 } ) );
}

$client = IO::Socket::INET->new(
  PeerPort => $SERVER_PORT,
  PeerAddr => $SERVER_ADDR,
  Type     => SOCK_STREAM,
  Proto    => 'tcp',
  Timeout  => 10 )
  or return_error( "Server Error", "Error communicating with server." );

my $results = "";

if ( defined( $contents{'security'} ) ) {

    # Implement CHAP-like security
    use Digest::MD5 qw(md5);    # This module is required for security to work.
    my $digest = md5( $contents{'security'} );
    send_data( $client, "digest" );
    $results = get_data($client);
    if ( $results ne "403" ) {
        return_error( "Server Error",
         "Error initiating authentication with server (results = \"$results\")."
        );
    }
    send_data( $client, $digest );
    $results = get_data($client);

    if ( $results ne "200" ) {
        return_error( "Server Error",
          "Error authenticating with server (results = \"$results\")." );
    }
}

if ( defined( $contents{'pattern'} ) ) {
    send_data( $client, "pattern" );
    $results = get_data($client);
    if ( $results ne "200" ) {
        return_error( "Server Error",
          "Error communicating with server (results = \"$results\")." );
    }
    send_data( $client, "0" );

    if ( $results ne "200" ) {
        return_error( "Server Error",
          "Error communicating with server (results = \"$results\")." );
    }
    $results = get_data($client);
    send_data( $client, $contents{'pattern'} );
    $results = get_data($client);

    if ( $results ne "200" ) {
        return_error( "Server Error",
          "Error communicating with server (results = \"$results\")." );
    }
    send_data( $client, $contents{'descr'} );

    $results = get_data($client);
    if ( $results eq "501" ) {
        return_error( "Bad Regular Expression",
          "The regular expression <I>$contents{'pattern'}</i> is not valid." );
    }
    elsif ( $results eq "404" ) {
        return_error( "SNMP Search Error",
"No objects were found matching the pattern <I>$contents{'pattern'}</i>.  Please alter your search pattern, and try again."
        );
    }

    return_data($results);
    exit(0);
}

if ( $contents{'xOps'} eq "" ) {
    send_data( $client, "simple" );
    $results = get_data($client);
    if ( $results ne "200" ) {
        return_error( "Server Error",
          "Error communicating with server (results = \"$results\")." );
    }
    send_data( $client, "0" ) if ( $contents{'bg'} ne "1" );
    send_data( $client, "1" ) if ( $contents{'bg'} eq "1" );

    if ( $results ne "200" ) {
        return_error( "Server Error",
          "Error communicating with server (results = \"$results\")." );
    }
    $results = get_data($client);
    send_data( $client, $contents{'oid'} );
    $results = get_data($client);

    if ( $results eq "404" ) {
        return_error( "SNMP Translate Error",
"Unable to translate <I>$contents{'oid'}</i>.  The object was either not found or invalid."
        );
    }

    return_data($results);
}
elsif ( $contents{'xOps'} eq "detail" ) {
    send_data( $client, "detail" );
    $results = get_data($client);
    if ( $results ne "200" ) {
        return_error( "Server Error", "Error communicating with server." );
    }
    send_data( $client, "0" ) if ( $contents{'bg'} ne "1" );
    send_data( $client, "1" ) if ( $contents{'bg'} eq "1" );

    if ( $results ne "200" ) {
        return_error( "Server Error",
          "Error communicating with server (results = \"$results\")." );
    }
    $results = get_data($client);
    send_data( $client, $contents{'oid'} );
    $results = get_data($client);

    if ( $results eq "404" ) {
        return_error( "SNMP Translate Error",
"Unable to translate <I>$contents{'oid'}</i>.  The object was either not found or invalid."
        );
    }

    return_data($results);
}
elsif ( $contents{'xOps'} eq "tree" ) {
    send_data( $client, "tree" );
    $results = get_data($client);
    if ( $results ne "200" ) {
        return_error( "Server Error", "Error communicating with server." );
    }
    send_data( $client, "0" ) if ( $contents{'bg'} ne "1" );
    send_data( $client, "1" ) if ( $contents{'bg'} eq "1" );

    if ( $results ne "200" ) {
        return_error( "Server Error",
          "Error communicating with server (results = \"$results\")." );
    }
    $results = get_data($client);
    send_data( $client, $contents{'oid'} );
    $results = get_data($client);

    if ( $results eq "404" ) {
        return_error( "SNMP Translate Error",
"Unable to display tree for <I>$contents{'oid'}</i>.  The object was either not found or invalid."
        );
    }

    return_data($results);
}

$client->close();

sub return_error {
    my ( $title, $message ) = @_;

    print "Content-type: text/html", "\n\n";

    print <<ERROR;
<H1>$title</H1>
<HR>$message</HR>
ERROR
    $client->close() if ($client);
    exit(0);
}

sub send_data {
    my ( $client, $data ) = @_;
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

    print <<EOH;
Content-type: text/html

<BODY BGCOLOR="#FFFFFF">

$data

</body>
</html>
EOH
}

