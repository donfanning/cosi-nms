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
use File::Copy;
use CRM;
use vars qw($uid $gid %files %perms $PS @dirs $PERL $NMSROOT);

$| = 1;

$NMSROOT = $ENV{'NMSROOT'};

if ( $CRM::CRM_OS ne "WIN" ) {
    %files = (
        'devexp.pl'   => "/opt/CSCOpx/bin",
        'devexp.xml'  => "/opt/CSCOpx/objects/devexp",
        'devexp.conf' => "/opt/CSCOpx/objects/devexp",
        'devexp.dtd'  => "/opt/CSCOpx/devexp/devexp",
    );
    %perms = (
        'devexp.pl'   => 0750,
        'devexp.xml'  => 0640,
        'devexp.conf' => 0640,
        'devexp.dtd'  => 0640,
    );
    @dirs = ( "/opt/CSCOpx/objects/devexp", "/opt/CSCOpx/htdocs/devexp" );
    $PERL = "/opt/CSCOpx/bin/perl";

    if ( defined( $ENV{'PX_USER'} ) ) {
        $uid = ( getpwnam( $ENV{'PX_USER'} ) )[2];
        $gid = ( getpwnam( $ENV{'PX_USER'} ) )[3];
    }
    else {
        $uid = ( getpwnam("bin") )[2];
        $gid = ( getpwnam("bin") )[3];
    }

    $PS = '/';
}
else {
    %files = (
        'devexp.pl'   => "$NMSROOT\\bin",
        'devexp.xml'  => "$NMSROOT\\objects\\devexp",
        'devexp.conf' => "$NMSROOT\\objects\\devexp",
        'devexp.dtd'  => "$NMSROOT\\htdocs\\devexp",
    );
    @dirs = ( "$NMSROOT\\objects\\devexp", "$NMSROOT\\htdocs\\devexp" );

    $PERL = "$NMSROOT\\bin\\perl";
    $PS   = "\\";

}

# Make the directories for install

return_error( 0, "Creating install directories ..." );
foreach (@dirs) {
    if ( !-d $_ ) {
        mkdir( $_, 0750 )
          or return_error( 1, "Unable to create directory $_: $!\n" );
    }
    chown( $uid, $gid, $_ ) if ( $CRM::CRM_OS ne "WIN" );

}
print " DONE!\n";

# Backup existing files
return_error( 0, "Backing up files ..." );
foreach ( keys {%files} ) {
    if ( -f $files{$_} . $PS . $_ ) {
        copy( $files{$_} . $PS . $_, $files{$_} . $PS . $_ . ".bak" )
          or return_error( 2,
            "Failed to copy file $files{$_}$PS$_ to $files{$_}$PS$_.bak: $!\n"
        );
        chown( $uid, $gid, $files{$_} . $PS . $_ . ".bak" )
          if ( $CRM::CRM_OS ne "WIN" );
        chmod( $perms{$_}, $files{$_} . $PS . $_ . ".bak" )
          if ( $CRM::CRM_OS ne "WIN" );
    }
}
print " DONE!\n";

# Copy files to their respective directory
return_error( 0, "Copying files ..." );
foreach ( keys(%files) ) {
    copy( $_, $files{$_} . $PS . $_ )
      or return_error( 2, "Failed to copy file $_ to $files{$_}$PS$_: $!\n" );
    chown( $uid, $gid, $files{$_} . $PS . $_ ) if ( $CRM::CRM_OS ne "WIN" );
    chmod( $perms{$_}, $files{$_} . $PS . $_ ) if ( $CRM::CRM_OS ne "WIN" );
}
print " DONE!\n";

return_error( 0, "Install completed successfully.\n" );
exit(0);

sub return_error {
    my ( $code, $msg ) = @_;
    my (%type);

    %type = (
        0 => 'INFO',
        1 => 'WARNING',
        2 => 'ERROR',
    );

    print $type{$code} . ": " . $msg;

    exit($code) if ( $code == 2 );
}

