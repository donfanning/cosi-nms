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

        # Set LD_LIBRARY_PATH to the location of the net-snmp (ucd-snmp) libraries.
        #$ENV{'LD_LIBRARY_PATH'} = '';

        # Zero out all previous environment variables.
        $ENV{'MIBS'}    = '';
        $ENV{'MIBDIRS'} = '';

        $MIBS = 'ALL';

        # Set this directory to the location where your MIBs are stored.
        $MIBDIRS = '/usr/local/share/snmp/mibs';

        # This is the name of the client CGI piece.  It should be a relative path
        # from the HTTP root.
        $ME = '/cgi-bin/snmptransc.pl';

        # Specify the location of the pidfile.  This is where the process id of the
        # server parent will be written to.  This is usually /var/run.
        $PIDFILE = '/var/run/snmptransd.pid';

        # Specify the local port for the server to bind to.  This is 3333
        # by default.
        $LOCAL_PORT = 3333;

        # Specify the number of seconds to wait before throwing a timeout exception.
        # This helps avoid denial of service attacks if the MIB tree is large.  The
        # default is 5 minutes.
        $TIMEOUT_SECS = 300;

        # Enable CHAP-like security for connecting to the server process.  This is
        # disable by default.  Set this to the name of the password file to
        # enable security.
        $SECURITY = "";

        # Enable global MIB module replacement.  This is a parsing option that tells
        # net-snmp to replace older loaded MIB modules with newer ones.  This can
        # overwrite older, less-descriptive, MIB objects with newer, more
        # descriptive ones (e.g. ifOperStatus from RFC1213 and IF).
        # WARNING: this can cause an inconsistent MIB hierarchy.  Use this option
        # with care.
        $REPLACE = 0;
}

use strict;
use vars
    qw($rcsid $SECURITY $PIDFILE $TIMEOUT_SECS $LOCAL_PORT $REPLACE $server $MAXLEN $PREFORK $MAX_CLIENTS_PER_CHILD %children $children $ME $MIBS $MIBDIRS $HTTPMIBS %contents @leave_indent $leave_was_simple $tree_buffer $last_ip);
use IO::Socket;
use Symbol;

use SNMP;
$SNMP::save_descriptions = 1;
$SNMP::replace_newer     = 1 if ($REPLACE);
$SNMP::use_long_names    = 1;
$SNMP::use_enums         = 1;
SNMP::initMib();
SNMP::addMibDirs($MIBDIRS);
SNMP::loadModules($MIBS);
use POSIX;

sub LOCK_SH { 1 }
sub LOCK_EX { 2 }
sub LOCK_NB { 4 }
sub LOCK_UN { 8 }

$rcsid = '$Id$';

$server = IO::Socket::INET->new(
        LocalPort => $LOCAL_PORT,
        Type      => SOCK_STREAM,
        Proto     => 'tcp',
        Reuse     => 1,
        Listen    => 10
    )
    or die "Error creating socket: $@\n";

if (-f $PIDFILE) {
        unless (open(PID, $PIDFILE)) {
                die "Unable to open $PIDFILE for reading: $!\n";
        }
        my $pid = <PID>;
        print "Server already running as process $pid.\n";
        close(PID);
        exit(1);
}

unless (open(PID, ">" . $PIDFILE)) {
        die "Unable to open $PIDFILE for writing: $!\n";
}
flock(PID, LOCK_EX);

print PID $$;

close(PID);

print "Server ready ...\n";

$MAXLEN                = 1024;
$PREFORK               = 5;
$MAX_CLIENTS_PER_CHILD = 5;
%children              = ();
$children              = 0;

$| = 1;

sub REAPER {
        $SIG{CHLD} = \&REAPER;
        my $pid = wait;
        $children--;
        delete $children{$pid};
}

sub HUNTSMAN {
        local ($SIG{CHLD}) = 'IGNORE';
        kill 'INT' => keys %children;
        CLEANUP();
}

sub CLEANUP {
        unlink $PIDFILE;
        exit(0);
}

for (1 .. $PREFORK) {
        make_new_child();
}

# Set up default signal handlers.  Not sure what this will do on Windows.
$SIG{CHLD} = \&REAPER;
$SIG{INT}  = \&HUNTSMAN;
$SIG{TERM} = \&HUNTSMAN;

while (1) {
        sleep;
        my $i;
        for ($i = $children ; $i < $PREFORK ; $i++) {
                make_new_child();
        }
}

sub make_new_child {
        my $pid;
        my $sigset;

        $sigset = POSIX::SigSet->new(SIGINT);
        sigprocmask(SIG_BLOCK, $sigset)
            or die "Can't block SIGINT for fork: $!\n";

        die "fork: $!" unless defined($pid = fork);

        if ($pid) {
                sigprocmask(SIG_UNBLOCK, $sigset)
                    or die "Can't unblock SIGINT for fork: $!\n";
                $children{$pid} = 1;
                $children++;
                return;
        } else {
                $SIG{INT} = 'DEFAULT';

                # This signal handler controls what to do if the snmptrans operation
                # runs for too long.  We will catch this timeout, and return an error.
                $SIG{ALRM} = sub { die "timeout" };

                sigprocmask(SIG_UNBLOCK, $sigset)
                    or die "Can't unblock SIGINT for fork: $!\n";

                my $i;
                for ($i = 0 ; $i < $MAX_CLIENTS_PER_CHILD ; $i++) {
                        my $client = $server->accept() or last;
                        snmptrans($client);
                        $client->close() if ($client);
                }
        }
        exit;
}

sub snmptrans {
        my ($client) = $_[0];
        my ($bg, $replace, $type, $size, $request, $numeric);
        my $data;

        # XXX Make all the client/server code a little clearer.  By this, I should
        # have codes that trigger options being set, and codes that indicate data.
        # Right now, things are too messy.

        if ($SECURITY ne "") {
                use Digest::MD5 qw(md5_hex);
                unless (open(PW, $SECURITY)) {
                        die "Cannot open password file $SECURITY: $!\n";
                }

                my $pw = <PW>;

                close(PW);

                chomp $pw;

                $type = get_data($client);
                if ($type eq "digest") {
                        send_data($client, "403");
                } else {
                        send_data($client, "501");
                        return;
                }
                my $digest = get_data($client);

                if ($digest eq md5_hex($pw)) {
                        send_data($client, "200");
                } else {
                        send_data($client, "403");
                        return;
                }
        }

        $type = get_data($client);
        send_data($client, "200");
        $bg = get_data($client);
        send_data($client, "200");
        if ($bg eq "1") {
                $SNMP::best_guess = 1;
        }
        $replace = get_data($client);
        send_data($client, "200");
        $request = get_data($client);

        if ($replace eq "1") {
                $SNMP::replace_newer = 1;
        }

        if ($request =~ /^(\d+\.)+\d+$/) {
                $request = "." . $request;
                $numeric = 1;
        } elsif ($request =~ /^\.(\d+\.)+\d+$/) {
                $numeric = 1;
        }

        if ($type eq "pattern") {
                send_data($client, "200");
                my $search_descr = get_data($client);
                if (!(eval { 'snmp' =~ /$request/i, 1 })) {
                        send_data($client, "501");
                        return;
                }

                if ($search_descr eq "1") {
                        $search_descr = 1;
                } else {
                        $search_descr = 0;
                }
                my $mib        = $SNMP::MIB{'.1'};    # Start from the root.
                my @occurances = ();
                eval {
                        alarm($TIMEOUT_SECS);
                        find_occurances($request, $search_descr, $mib,
                                \@occurances);
                        alarm(0);
                };

                if ($@) {
                        if ($@ =~ /timeout/) {
                                send_data($client, "502");
                                return;
                        } else {
                                alarm(0);
                                send_data($client, "500");
                                return;
                        }
                }
                my ($occurance);

                if (!(scalar @occurances)) {
                        send_data($client, "404");
                        return;
                }
                $data = "<H3>Found " . scalar @occurances . " match(es)</h3>\n";
                $data .= "<TABLE BORDER=\"0\">\n";

                foreach $occurance (@occurances) {
                        $data .= "<TR>\n";
                        my ($value, $isbranch) = split(/\|/, $occurance);
                        if ($isbranch) {
                                $data .= "<TD>$value</td>\n";
                                $data .=
                                    "<TD><SMALL>[<A HREF=\"$ME?oid=$value&xOps=detail\">detail</a>] | [<A HREF=\"$ME?oid=$value&xOps=tree\">tree</a>]</small></td>\n";
                        } else {
                                $data .= "<TD>$value</td>\n";
                                $data .=
                                    "<TD><SMALL>[<A HREF=\"$ME?oid=$value&xOps=detail\">detail</a>] | [<FONT COLOR=\"lightgrey\">tree</font>]</small></td>\n";
                        }
                        $data .= "</tr>\n";
                }
                $data .= "</table>\n";
                undef @occurances;
                send_data($client, $data);
        } elsif ($type eq "simple") {
                my $trans = SNMP::translateObj($request);
                my ($oid, $mib);
                $oid = $request;

                if (!defined($trans)) {
                        send_data($client, "404");
                        return;
                }
                if ($numeric) {
                        $mib = $SNMP::MIB{$request};
                } else {
                        $mib = $SNMP::MIB{$trans};
                }

                my $type   = $$mib{'type'};
                my $syntax = $$mib{'syntax'};
                if ($type eq "OBJECTID") {
                        $type = "OBJECT ID";
                }
                if ($type eq "INTEGER" || $type eq "INTEGER32") {
                        $type = "Integer";
                } elsif ($type eq "OCTETSTR") {
                        $type = "OCTET STRING";
                } elsif ($type eq "NETADDR") {
                        $type = "NetAddress";
                } elsif ($type eq "IPADDR") {
                        $type = "IpAddress";
                } elsif ($type eq "COUNTER") {
                        $type = "Counter";
                } elsif ($type eq "GAUGE") {
                        $type = "Gauge";
                } elsif ($type eq "TICKS") {
                        $type = "TimeTicks";
                } elsif ($type eq "OPAQUE") {
                        $type = "Opaque";
                } elsif ($type eq "NULL") {
                        $type = "Null";
                } elsif ($type eq "BITSTRING" || $type eq "BITS") {
                        $type = "BitString";
                } elsif ($type eq "COUNTER64") {
                        $type = "Counter64";
                } elsif ($type eq "NSAPADDRESS") {
                        $type = "NsapAddress";
                } elsif (  $type eq "UINTEGER"
                        || $type eq "UINTEGER32"
                        || $type eq "UNSIGNED32")
                {
                        $type = "UInteger";
                } elsif ($type eq "NOTIF" || $type eq "TRAP") {
                        $type = "Trap";
                }

                if ($type eq "") {
                        $type = $syntax;
                }

                $data =
                      "<PRE>" . $oid . " = " . $trans . " (" . $type
                    . ")</pre>\n";
                send_data($client, $data);
        } elsif ($type eq "detail") {
                my $trans = SNMP::translateObj($request);
                if (!defined($trans)) {
                        send_data($client, "404");
                        return;
                }

                my $mib;
                if ($numeric) {
                        $mib = $SNMP::MIB{$request};
                } else {
                        $mib = $SNMP::MIB{$trans};
                }
                my $modules  = $$mib{'moduleID'};
                my $type     = $$mib{'type'};
                my $access   = $$mib{'access'};
                my $children = $$mib{'children'};
                my $status   = $$mib{'status'};
                my $syntax   = $$mib{'syntax'};
                my $descr    = $$mib{'description'};
                my $label    = $$mib{'label'};
                my $tc       = $$mib{'textualConvention'};
                my $subID    = $$mib{'subID'};
                my $enums    = $$mib{'enums'};
                my $ranges   = $$mib{'ranges'};
                my $hint     = $$mib{'hint'};
                my $indexes  = $$mib{'indexes'};
                my $varbinds = $$mib{'varbinds'};

                if ($access eq "Create") {
                        $access = "read-create";
                } elsif ($access eq "NoAccess") {
                        $access = "not-accessible";
                } elsif ($access eq "ReadOnly") {
                        $access = "read-only";
                } elsif ($access eq "ReadWrite") {
                        $access = "read-write";
                } elsif ($access eq "Notify") {
                        $access = "notify";
                }

                if ($type eq "OBJECTID") {
                        $type = "OBJECT ID";
                }
                if ($type eq "INTEGER" || $type eq "INTEGER32") {
                        $type = "Integer";
                } elsif ($type eq "OCTETSTR") {
                        $type = "OCTET STRING";
                } elsif ($type eq "NETADDR") {
                        $type = "NetAddress";
                } elsif ($type eq "IPADDR") {
                        $type = "IpAddress";
                } elsif ($type eq "COUNTER") {
                        $type = "Counter";
                } elsif ($type eq "GAUGE") {
                        $type = "Gauge";
                } elsif ($type eq "TICKS") {
                        $type = "TimeTicks";
                } elsif ($type eq "OPAQUE") {
                        $type = "Opaque";
                } elsif ($type eq "NULL") {
                        $type = "Null";
                } elsif ($type eq "BITSTRING" || $type eq "BITS") {
                        $type = "BitString";
                } elsif ($type eq "COUNTER64") {
                        $type = "Counter64";
                } elsif ($type eq "NSAPADDRESS") {
                        $type = "NsapAddress";
                } elsif (  $type eq "UINTEGER"
                        || $type eq "UINTEGER32"
                        || $type eq "UNSIGNED32")
                {
                        $type = "UInteger";
                } elsif ($type eq "NOTIF" || $type eq "TRAP") {
                        $type = "Trap";
                }

                if ($type eq "") {
                        $type = $syntax;
                }

                #	$descr =~ s/\s+/ /g;
                if ($descr) {
                        $descr = "\"" . $descr . "\"";
                }

                my $oid;
                $data = "<PRE>\n";
                if ($numeric) {
                        $data .= $request;
                        $oid = $request;

                } else {
                        $data .= $trans;
                        $oid = $trans;
                }
                $oid =~ s/^\.//;
                $data .= "\n";
                $data .= $label . " OBJECT-TYPE\n";
                my $module;
                $data .= "\t-- FROM\t";

                if (ref($modules) eq "ARRAY") {
                        foreach $module (@{$modules}) {
                                $data .= $module . ", ";
                        }
                } else {
                        $data .= $modules;
                }
                $data =~ s/, $//;
                $data .= "\n";

                if ($tc ne "") {
                        $data .= "\t-- TEXTUAL CONVENTION $tc\n";
                }
                if ($type ne "" && $type ne "Trap") {
                        if (defined $enums && scalar(keys %{$enums}) > 0) {
                                $data .= "\tSYNTAX\t\t" . $type . " { ";
                                my $cpos = 0;
                                my $cmax = 1000000 - 16;
                                my $enum;

                                foreach $enum (
                                        sort { $enums->{$a} <=> $enums->{$b} }
                                        keys %{$enums}
                                    )
                                {
                                        my $buf;
                                        my $bufw;
                                        $buf = sprintf "%s(%d)", $enum,
                                            $enums->{$enum};
                                        $cpos += ($bufw = length($buf) + 2);

                                        if ($cpos >= $cmax) {
                                                $data .= "\n";
                                                $cpos = $bufw;
                                        }
                                        $data .= $buf;

                                        if ($enums != $$mib{'enums'}) {
                                                $data .= ", ";
                                        }
                                }
                                $data =~ s/, $//;
                                $data .= " }\n";
                        } else {
                                my $range;

                                if (defined $ranges && (scalar(@{$ranges}) > 0))
                                {
                                        $data .= "\tSYNTAX\t\t$type (";
                                        foreach $range (@{$ranges}) {
                                                if ($range->{'low'} ==
                                                        $range->{'high'})
                                                {
                                                        $data .=
                                                            $range->{'low'};
                                                } else {
                                                        $data .=
                                                              $range->{'low'}
                                                            . ".."
                                                            . $range->{'high'};
                                                }
                                                $data .= "|";
                                        }
                                        $data =~ s/\|$//;
                                        $data .= ")";
                                        $data .= "\n";
                                } else {
                                        $data .= "\tSYNTAX\t\t" . $type . "\n";
                                }
                        }

                        if ($hint ne "") {
                                $data .= "\tDISPLAY-HINT\t\"" . $hint . "\"\n";
                        }
                        $data .= "\tMAX-ACCESS\t" . $access . "\n";
                        $data .= "\tSTATUS\t\t" . $status . "\n";
                }

                if ($type eq "Trap") {
                        $data .= "\tTRAP\n";
                }
                if (defined $indexes && scalar(@{$indexes}) > 0) {
                        $data .= "\tINDEXES\t\t" . "{ ";
                        my $cpos = 0;
                        my $cmax = 1000000 - 16;
                        my $index;

                        foreach $index (@{$indexes}) {
                                my $buf;
                                my $bufw;
                                $buf = sprintf
                                    "<A HREF=\"$ME?oid=%s&xOps=detail\">%s</A>",
                                    $index, $index;
                                $cpos += ($bufw = length($buf) + 2);

                                if ($cpos >= $cmax) {
                                        $data .= "\n";
                                        $cpos = $bufw;
                                }
                                $data .= $buf;

                                if ($indexes != $$mib{'indexes'}) {
                                        $data .= ", ";
                                }
                        }
                        $data =~ s/, $//;
                        $data .= " }\n";
                }

                if ($varbinds && scalar(@{$varbinds}) > 0) {
                        $data .= "\tVARBINDS\t" . "{ ";
                        my $cpos = 0;
                        my $cmax = 1000000 - 16;
                        my $varbind;

                        foreach $varbind (@{$varbinds}) {
                                my $buf;
                                my $bufw;
                                $buf = sprintf
                                    "<A HREF=\"$ME?oid=%s&xOps=detail\">%s</A>",
                                    $varbind, $varbind;
                                $cpos += ($bufw = length($buf) + 2);

                                if ($cpos >= $cmax) {
                                        $data .= "\n";
                                        $cpos = $bufw;
                                }
                                $data .= $buf;

                                if ($varbinds != $$mib{'varbinds'}) {
                                        $data .= ", ";
                                }
                        }
                        $data =~ s/, $//;
                        $data .= " }\n";
                }

                if ($descr) {
                        $data .= "\tDESCRIPTION    " . $descr . "\n";
                }
                $data .= "::= { ";
                my @parts = split(/\./, $oid);
                my ($savepart);
                $SNMP::use_long_names = 0;
                my $i;

                for ($i = 0 ; $i < $#parts ; $i++) {
                        $savepart .= ".$parts[$i]";
                        my $tmp = SNMP::translateObj($savepart);
                        $tmp =~ s/^\.//;
                        $data .= $tmp . "($parts[$i]) ";
                }
                $data .= "$parts[$i] ";
                $data .= "}\n";
                $data .= "</pre>\n";
                send_data($client, $data);
        } elsif ($type eq "tree") {
                my $trans;
                $data = "<PRE>\n";

                if ($numeric) {
                        my $mib  = $SNMP::MIB{$request};
                        my $foid = "";
                        foreach my $soid (
                                split(/\./, ($mib->{'parent'})->{'objectID'}))
                        {
                                next unless $soid;
                                $foid .= "." . $soid;
                                $data .=
                                    ".<A HREF=\"$ME?oid=$foid&xOps=tree\" TITLE=\"$foid\" ALT=\"$foid\"><FONT COLOR=\"green\">$soid</font></a>";
                        }
                        $data .= "\n";
                        eval {
                                alarm($TIMEOUT_SECS);
                                $data .= walkMIB($client, $request, $request);
                                alarm(0);
                        };

                        if ($@) {
                                if ($@ =~ /timeout/) {
                                        send_data($client, "502");
                                        return;
                                } else {
                                        alarm(0);
                                        send_data($client, "500");
                                        return;
                                }
                        }
                } else {
                        $trans = SNMP::translateObj($request);
                        my $mib  = $SNMP::MIB{$trans};
                        my $foid = "";
                        foreach my $soid (
                                split(/\./, ($mib->{'parent'})->{'objectID'}))
                        {
                                next unless $soid;
                                $foid .= "." . $soid;
                                $data .=
                                    ".<A HREF=\"$ME?oid=$foid&xOps=tree\" TITLE=\"$foid\" ALT=\"$foid\"><FONT COLOR=\"green\">$soid</font></a>";
                        }
                        $data .= "\n";
                        eval {
                                alarm($TIMEOUT_SECS);
                                $data .= walkMIB($client, $request, $trans);
                                alarm(0);
                        };

                        if ($@) {
                                if ($@ =~ /timeout/) {
                                        send_data($client, "502");
                                        return;
                                } else {
                                        alarm(0);
                                        send_data($client, "500");
                                        return;
                                }
                        }
                }
                $data .= "</pre>\n";
                send_data($client, $data);
        } else {
                send_data($client, "500");
        }
        undef $type;
        undef $request;
        undef $data;
        undef $tree_buffer;
}

sub find_occurances {
        my ($pattern, $search_descr, $mib, $patterns) = @_;
        my ($tp, $tmp, $condition);

        foreach $tp (@{$mib->{'children'}}) {
                $condition = 0;
                if ($search_descr && length($tp->{'description'})) {
                        $condition = 1
                            if (   $tp->{'label'} =~ /$pattern/i
                                || $tp->{'description'} =~ /$pattern/i);
                } else {
                        $condition = 1 if ($tp->{'label'} =~ /$pattern/i);
                }

                if ($condition) {
                        if (scalar(@{$tp->{'children'}})) {
                                $tmp = $tp->{'label'} . "|" . 1;
                        } else {
                                $tmp = $tp->{'label'} . "|" . 0;
                        }

                        push @{$patterns}, $tmp;
                }
        }
        foreach $tp (@{$mib->{'children'}}) {
                if (scalar $tp->{'children'}) {
                        find_occurances($pattern, $search_descr, $tp,
                                $patterns);
                }
        }
}

sub walkMIB {
        my ($client, $pattern, $oid) = @_;
        if (!defined($oid)) {
                send_data($client, "404");
                return undef;
        }
        my $data;
        $leave_indent[0] = ' ';
        $leave_was_simple = 0;
        $data = print_mib_leaves($oid, 1000000);

        return $data;
}

sub print_mib_leaves {
        my ($oid, $level) = @_;
        my $nextOid;
        my ($cp, $child);
        my $test_count = 0;
        my $size       = 0;
        my $ip         = scalar(@leave_indent) - 1;
        my $last_ipch  = $leave_indent[$ip];

        $leave_indent[$ip] = '+';
        my $mib = $SNMP::MIB{$oid};
        $cp = $mib->{'children'};
        foreach $child (@{$cp}) {
                $test_count++;
        }
        undef $cp;
        undef $child;

        my $st = SNMP::translateObj($$mib{'label'});
        my $sm = $SNMP::MIB{$st};
        my $sd = $$sm{'description'};
        $sd =~ s/\s+/ /g;

        if ($$mib{'type'} eq "") {
                if ($test_count) {
                        $tree_buffer .=
                            join("", @leave_indent)
                            . "--<A HREF=\"$ME?oid=$$mib{'label'}&xOps=tree\"><FONT COLOR=\"green\">$$mib{'label'}</FONT></A>($$mib{'subID'}) <SMALL><A HREF=\"$ME?oid=$$mib{'label'}&xOps=detail\" title=\"$sd\" alt=\"$sd\"><FONT COLOR=\"#DC00DC\">detail</FONT></A></SMALL>\n";
                } else {
                        $tree_buffer .=
                            join("", @leave_indent)
                            . "--<A HREF=\"$ME?oid=$$mib{'label'}&xOps=detail\" title=\"$sd\" alt=\"$sd\"><FONT COLOR=\"#DC00DC\">$$mib{'label'}</FONT></A>($$mib{'subID'})\n";
                }

        } else {
                my ($acc, $typ);
                if ($$mib{'access'} eq "NoAccess") {
                        $acc = "----";
                } elsif ($$mib{'access'} eq "ReadOnly") {
                        $acc = "-R--";
                } elsif ($$mib{'access'} eq "ReadWrite") {
                        $acc = "-RW-";
                } elsif ($$mib{'access'} eq "Notify") {
                        $acc = "---N";
                } elsif ($$mib{'access'} eq "Create") {
                        $acc = "CR--";
                } else {
                        $acc = "    ";
                }

                if ($$mib{'type'} eq "OBJECTID") {
                        $typ = "ObjID    ";
                } elsif ($$mib{'type'} eq "OCTETSTR") {
                        $size = 1;
                        $typ  = "String   ";
                } elsif (  $$mib{'type'} eq "INTEGER"
                        || $$mib{'type'} eq "INTEGER32")
                {

                        if (scalar(keys %{$mib->{'enums'}}) > 0) {
                                $typ = "EnumVal  ";
                        } else {
                                $typ = "Integer  ";
                        }
                } elsif ($$mib{'type'} eq "NETADDR") {
                        $typ = "NetAddr  ";
                } elsif ($$mib{'type'} eq "IPADDR") {
                        $typ = "IpAddr   ";
                } elsif ($$mib{'type'} eq "COUNTER") {
                        $typ = "Counter  ";
                } elsif ($$mib{'type'} eq "GAUGE") {
                        $typ = "Gauge    ";
                } elsif ($$mib{'type'} eq "TICKS") {
                        $typ = "Timeticks";
                } elsif ($$mib{'type'} eq "OPAQUE") {
                        $size = 1;
                        $typ  = "Opaque   ";
                } elsif ($$mib{'type'} eq "NULL") {
                        $typ = "Null     ";
                } elsif ($$mib{'type'} eq "COUNTER64") {
                        $typ = "Counter64";
                } elsif (  $$mib{'type'} eq "BITSTRING"
                        || $$mib{'type'} eq "BITS")
                {
                        $typ = "BitString";
                } elsif ($$mib{'type'} eq "NSAPADDRESS") {
                        $typ = "NsapAddr ";
                } elsif (  $$mib{'type'} eq "UINTEGER"
                        || $$mib{'type'} eq "UINTEGER32"
                        || $$mib{'type'} eq "UNSIGNED32")
                {
                        $typ = "UInteger ";
                } elsif ($$mib{'type'} eq "NOTIF" || $$mib{'type'} eq "TRAP") {
                        $typ = "<B>Trap</B>";
                } else {
                        $typ = "         ";
                }

                my $st = SNMP::translateObj($$mib{'label'});
                my $sm = $SNMP::MIB{$st};
                my $sd = $$sm{'description'};
                $sd =~ s/\s+/ /g;

                if ($test_count) {
                        $tree_buffer .=
                            join("", @leave_indent)
                            . "-- $acc $typ <A HREF=\"$ME?oid=$$mib{'label'}&xOps=tree\"><FONT COLOR=\"green\">$$mib{'label'}</FONT></A>($$mib{'subID'}) <SMALL><A HREF=\"$ME?oid=$$mib{'label'}&xOps=detail\" title=\"$sd\" alt=\"$sd\"><FONT COLOR=\"#DC00DC\">detail</FONT></A></SMALL>\n";
                } else {
                        $tree_buffer .=
                            join("", @leave_indent)
                            . "-- $acc $typ <A HREF=\"$ME?oid=$$mib{'label'}&xOps=detail\" title=\"$sd\" alt=\"$sd\"><FONT COLOR=\"#DC00DC\">$$mib{'label'}</FONT></A>($$mib{'subID'})\n";
                }

                $leave_indent[$ip] = $last_ipch;
                if ($$mib{'textualConvention'} ne "") {
                        $tree_buffer .=
                            join("", @leave_indent)
                            . "        Textual Convention: $$mib{'textualConvention'}\n";
                }

                if (scalar(keys %{$mib->{'enums'}}) > 0) {
                        my $ep   = $$mib{'enums'};
                        my $cpos = 0;
                        my $cmax = $level - scalar(@leave_indent) - 16;
                        $tree_buffer .=
                            join("", @leave_indent) . "        Values: ";
                        my $key;

                        foreach $key (
                                sort { $ep->{$a} <=> $ep->{$b} }
                                keys %{$ep}
                            )
                        {
                                my $buf;
                                my $bufw;
                                $buf = sprintf "%s(%d)", $key, $ep->{$key};
                                $cpos += ($bufw = length($buf) + 2);
                                if ($cpos >= $cmax) {
                                        $tree_buffer .= "\n"
                                            . join("", @leave_indent)
                                            . "                ";
                                        $cpos = $bufw;
                                }
                                $tree_buffer .= $buf;

                                if ($ep != $$mib{'enums'}) {
                                        $tree_buffer .= ", ";
                                }

                        }
                        $tree_buffer =~ s/, $//;
                        $tree_buffer .= "\n";
                }
        }

        if ($mib->{'ranges'} && scalar(@{$mib->{'ranges'}}) > 0) {
                my $range;
                if ($size == 1) {
                        $tree_buffer .=
                            join("", @leave_indent) . "        Size: ";
                } else {
                        $tree_buffer .=
                            join("", @leave_indent) . "        Range: ";
                }

                foreach $range (@{$mib->{'ranges'}}) {
                        my $key;
                        if ($range->{'low'} == $range->{'high'}) {
                                $tree_buffer .= $range->{'low'};
                        } else {
                                $tree_buffer .=
                                    "$range->{'low'}..$range->{'high'}";
                        }
                        $tree_buffer .= "|";
                }
                $tree_buffer =~ s/\|$//;
                $tree_buffer .= "\n";
        }
        $leave_indent[$ip] = $last_ipch;
        push @leave_indent, ' ';
        push @leave_indent, ' ';
        push @leave_indent, '|';
        $leave_was_simple = ($$mib{'type'} ne "");

        my ($count, $i);
        $count = 0;

        my $children = $$mib{'children'};
        foreach $nextOid (@{$children}) {
                $count++;
        }
        if ($count) {
                $i = 0;
                my $np;

                foreach $np (sort { $a->{'subID'} <=> $b->{'subID'} }
                        @{$children})
                {
                        if (
                                (
                                           $leave_was_simple == 0
                                        || $leave_was_simple eq ""
                                )
                                || ($np->{'type'} eq "")
                            )
                        {
                                $tree_buffer .= join("", @leave_indent) . "\n";
                        }

                        if ($i == $count) {
                                my $j;
                                for ($j = 0 ; $j < 3 ; $j++) {
                                        push @leave_indent, " ";
                                }
                        }

                        print_mib_leaves($np->{'objectID'}, $level);
                        $i++;

                }
                $leave_was_simple = 0;
        }
        my $k;
        for ($k = 0 ; $k < 3 ; $k++) {
                pop @leave_indent;
        }
        return $tree_buffer;
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
        $data =~ s/\W+$//g;
        $data =~ s/<br>/\n/g;
        return $data;
}

