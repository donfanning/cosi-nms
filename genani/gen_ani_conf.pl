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

use strict;
use CRM;
use Getopt::Std;

use lib "$ENV{'NMSROOT'}/objects/genani";
use Rules;

sub LOCK_SH { 1 }
sub LOCK_EX { 2 }
sub LOCK_NB { 4 }
sub LOCK_UN { 8 }

use vars qw(
  $PS
  $ANI_SNMP_CONF
  $VERSION
  $OUTFILE
  $OFFLINE
  $RULES
  $VERBOSE
  $PDEXEC
  $PDTERM
  $NULL
);

if ( $CRM::CRM_OS eq "WIN" ) {
    $PS = '\\';
}
else {
    $PS = '/';
}

$ANI_SNMP_CONF = join ( $PS, $ENV{'NMSROOT'}, 'etc', 'cwsi', 'anisnmp.conf' );
$VERSION = '1.0';
$OUTFILE = $ANI_SNMP_CONF;
$OFFLINE = 0;
$RULES   = join ( $PS, $ENV{'NMSROOT'}, 'objects', 'genani', 'ani_rules.dat' );
$PDTERM = join ( $PS, $ENV{'NMSROOT'}, 'bin', 'pdterm' );
$PDEXEC = join ( $PS, $ENV{'NMSROOT'}, 'bin', 'pdexec' );

if ( $CRM::CRM_OS eq "WIN" ) {
    $NULL = "2>&1 >nul";
}
else {
    $NULL = "2>&1 >/dev/null";
}

my $opts = {};
getopts( 'r:svho:', $opts );

if ( $opts->{'h'} ) {
    usage();
    exit(0);
}

$OUTFILE = $opts->{'o'} if ( $opts->{'o'} );
$OFFLINE = 1 if ( $opts->{'s'} );
$RULES = $opts->{'r'} if ( $opts->{'r'} );
$VERBOSE = 1 if ( $opts->{'v'} );

$SIG{TERM} = 'IGNORE';    # Ignore SIGTERM to help keep us out of dmgtd grasp.

if ( scalar(@ARGV) != 1 ) {
    usage();
    exit(1);
}

my $rules = new Rules($RULES);    # That's a lot of rules ;-).
if ( !$rules->readRules() ) {
    die "ERROR: " . $rules->error() . "\n";
}
print STDERR "INFO: Read rules successfully\n" if ($VERBOSE);

my $rulesRef   = $rules->rules();
my $rulesIndex = $rules->rules_index();
my $vars       = $rules->vars();
my $actions    = $rules->actions();

unless ( open( OUT, ">" . $OUTFILE ) ) {
    die "ERROR: Unable to open $OUTFILE: $!\n";
}
flock( OUT, LOCK_EX );

unless ( open( IN, $ARGV[0] ) ) {
    die "ERROR: Unable to open $ARGV[0]: $!\n";
}
flock( IN, LOCK_SH );

if ($OFFLINE) {
    print STDERR "INFO: Stopping ANIServer ..." if ($VERBOSE);
    die "Unable to stop ANIServer\n"
      if ( system( $PDTERM . " ANIServer $NULL" ) );
    print STDERR " DONE\n" if ($VERBOSE);
}

my $line;
while ( $line = <IN> ) {
    chomp $line;
    s/#.*//;
    s/^\s+//;
    s/\s+$//;
    next unless length $line;
    my ($name) = split ( /,/, $line );
    my ( $rule, $match );
    $match = 0;

    foreach $rule ( @{$rulesIndex} ) {
        if ( $name =~ /$rulesRef->{$rule}->{name}/i
            && $rulesRef->{$rule}->{type} !~ /static/i )
        {

            # We have a match.
            print STDERR "INFO: $name matches rule $rule\n" if ($VERBOSE);
            $match = 1;
            print OUT $name . ":" . ( ( $actions->{$rule}->{readcomm} ) ?
              $actions->{$rule}->{readcomm} : $vars->{READ_COMM} ) . "::"
              . ( ( $actions->{$rule}->{timeout} ) ?
              $actions->{$rule}->{timeout} : $vars->{TIMEOUT} ) . ":"
              . ( ( $actions->{$rule}->{retries} ) ?
              $actions->{$rule}->{retries} : $vars->{RETRIES} ) . ":::"
              . ( ( $actions->{$rule}->{writecomm} ) ?
              $actions->{$rule}->{writecomm} : $vars->{WRITE_COMM} ) . "\n";
        }
        elsif ( $rulesRef->{$rule}->{type} =~ /static/i ) {
            print STDERR "INFO: Adding static rule, $rule" if ($VERBOSE);
            print OUT $name . ":" . ( ( $actions->{$rule}->{readcomm} ) ?
              $actions->{$rule}->{readcomm} : $vars->{READ_COMM} ) . "::"
              . ( ( $actions->{$rule}->{timeout} ) ?
              $actions->{$rule}->{timeout} : $vars->{TIMEOUT} ) . ":"
              . ( ( $actions->{$rule}->{retries} ) ?
              $actions->{$rule}->{retries} : $vars->{RETRIES} ) . ":::"
              . ( ( $actions->{$rule}->{writecomm} ) ?
              $actions->{$rule}->{writecomm} : $vars->{WRITE_COMM} ) . "\n";
        }

    }

    if ( !$match ) {
        print STDERR
          "INFO: Unable to find a rule to match $name; will use default\n"
          if ($VERBOSE);
        print OUT $name . ":" . $vars->{READ_COMM} . "::" . $vars->{TIMEOUT}
          . ":" . $vars->{RETRIES} . ":::" . $vars->{WRITE_COMM} . "\n";
    }

}

print STDERR "INFO: Adding default rule ..." if ($VERBOSE);
print OUT "*.*.*.*:" . $vars->{READ_COMM} . "::" . $vars->{TIMEOUT} . ":"
  . $vars->{RETRIES} . ":::" . $vars->{WRITE_COMM} . "\n";
print STDERR " DONE\n";

close(OUT);
close(IN);

if ($OFFLINE) {
    print STDERR "INFO: Restarting ANIServer ..." if ($VERBOSE);
    die "Unable to restart ANIServer\n"
      if ( system( $PDEXEC . " ANIServer $NULL" ) );
    print STDERR " DONE\n" if ($VERBOSE);
}

exit(0);

sub usage {
    print <<EOH;
gen_ani_conf.pl $VERSION (c) 2001 MarcusCom, Inc. 

usage: gen_ani_conf.pl [-shv] [-r filename] [-o filename] filename

       h    print this message
       s    shutdown ANIServer before generating the anisnmp.conf file
       v    print verbose messages
       r    _filename_ specifies rules file to read; default is 
            $RULES
       o    _filename_ specifies output file; default is 
            $ANI_SNMP_CONF
       
	   filename    the file to read the input data from
EOH
}
