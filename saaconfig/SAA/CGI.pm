package SAA::CGI;

use strict;
require 5.002;
use lib qw(..);
use conf::prefs qw($TEMP_DIR $MAX_SESSIONS);

use vars qw(@ISA @EXPORT);
use Exporter;
@ISA    = qw(Exporter);
@EXPORT = qw(
    return_error
    session_start
    session_destroy
    session_register
    $SESS_USER
    $SESS_PERMS
);

use vars qw($SESS_USER $SESS_PERMS);

sub return_error {
        my ($q, $reason) = @_;

        print $q->header("text/html");
        print $q->start_html("SAA Configurator Error");
        print $q->h1("SAA Configurator Error");
        print $q->p("The SAA Configurator encountered the following error: ");
        print $q->p($q->i($reason));
        print $q->end_html;

        exit(0);
}

sub session_start {
        my ($q) = shift;

        my $cookie = $q->cookie(-name => "sess");

        if (defined($cookie)) {
                my $session_file = $TEMP_DIR . "/sess_" . $cookie;
                local *FILE;

                -e $session_file or return;
                open FILE, $session_file or return;
                my $q_saved = new CGI(\*FILE) or return;
                close FILE;

                $SESS_USER  = $q_saved->param("user");
                $SESS_PERMS = $q_saved->param("perms");
        } else {
                return;
        }

        1;
}

sub session_register {
        my ($q) = shift;

        my $id           = _unique_id();
        my $session_file = $TEMP_DIR . "/sess_" . $id;
        local (*FILE, *DIR);

        $SESS_USER  = $q->param("user");
        $SESS_PERMS = $q->param("perms");

        my $num_files = 0;
        opendir DIR, $TEMP_DIR;
        $num_files++ while readdir DIR;
        closedir DIR;

        if ($num_files > $MAX_SESSIONS) {
                return;
        }

        open FILE, ">" . $session_file or return;
        $q->save(\*FILE);
        close FILE;

        $id;
}

sub session_destroy {
        my ($q) = shift;

        my $cookie = $q->cookie(-name => "sess");
        undef $SESS_USER;
        undef $SESS_PERMS;

        if (defined($cookie)) {
                my $session_file = $TEMP_DIR . "/sess_" . $cookie;

                unlink $session_file if -e $session_file;
        }

        1;
}

sub _unique_id {
        return $ENV{UNIQUE_ID} if exists $ENV{UNIQUE_ID};

        require Digest::MD5;

        my $md5    = new Digest::MD5;
        my $remote = $ENV{REMOTE_ADDR} . $ENV{REMOTE_PORT};

        my $id = $md5->md5_base64(time, $$, $remote);
        $id =~ tr|+/=|-_.|;

        $id;
}

1;
