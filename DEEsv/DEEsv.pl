#!/opt/CSCOpx/bin/perl
#-
# Copyright (c) 2002 Joe Marcus Clarke <marcus@marcuscom.com>
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

use strict;
use vars qw($PS $COMMAND $CLASSPATH $TMPDIR $NMSROOT);

$PS = '/';

if ($^O eq "MSWin32") {
        use CRM;
        $PS      = "\\";
        $TMPDIR  = $ENV{'PX_TMPDIR'};
        $NMSROOT = $ENV{'NMSROOT'};
} else {
        $ENV{'PATH'} = '/bin:/usr/bin';
        ($TMPDIR)  = ($ENV{'PX_TMPDIR'} =~ /(^[\/\w+\/?]+$)/);
        ($NMSROOT) = ($ENV{'NMSROOT'}   =~ /(^[\/\w+\/?]+$)/);
}

$CLASSPATH = $NMSROOT . "/lib/classpath/deesv.jar";

my $args  = "";
my $isSep = 0;
foreach (@ARGV) {
        my $tmp = "";
        if ($isSep) {
                ($tmp) = ($_ =~ /(^.$)/);
                $tmp   = "\\" . $tmp;
                $isSep = 0;
        } else {
                if ($_ eq "-sep") {
                        $isSep = 1;
                }
                ($tmp) = ($_ =~ /(^[^\&\`\(\)\{\}\|\;]+$)/);
        }
        $args .= $tmp . " ";
}

$args =~ s/^\s+//;
$args =~ s/\s+$//;

$COMMAND = join ($PS, $NMSROOT, "bin", "cwjava");
$COMMAND .= " -cw " . $NMSROOT . " -cp:a " . $CLASSPATH;
$COMMAND .= " -Xms32m";
$COMMAND .= " -Xmx512m";
$COMMAND .= " -DTMPDIR=" . $TMPDIR . " -DNMSROOT=" . $NMSROOT;
$COMMAND .= " com.marcuscom.deesv.DEEsv " . $args;

system($COMMAND);
