#!/usr/bin/perl -wT

use strict;
require 5.002;
use CGI;
use CGI::Carp qw(fatalsToBrowser);
use lib "..";    # XXX For testing
use SAA::DB;
use SAA::User qw(PERMS_GUEST PERMS_USER PERMS_ADMIN);
use SAA::CGI;

$| = 1;

my $q = new CGI();

if ( !$q->param("form_user") ) {

    # Note, this should never be reached if JavaScript is doing its job.
    print "Location: /cgi-bin/bad-login.cgi?msg=Please enter your username\n\n";
    exit(0);
}

# Create a new DB object.
my $db      = new SAA::DB;
my $db_user =
  $db->get_object( 'SAA::User', Username => $q->param("form_user") );

if ( !$db_user ) {

    # User doesn't exist in the database.
    print "Location: /cgi-bin/bad-login.cgi\n\n";
    exit(0);
}

# Check the user's password.
if ( !$db_user->validate_passwd( $q->param("form_pass") ) ) {
    print "Location: /cgi-bin/bad-login.cgi\n\n";
    exit(0);
}

my $q_sess =
  new CGI( 'user' => $db_user->username(), 'perms' => $db_user->perms() );

# Save the persistent user data.
my $sess_id = session_register($q_sess);

if ( !$sess_id ) {
    return_error( $q, "Failed to establish login session" );
}

my $cookie = $q->cookie( -name => "sess", -value => $sess_id );

if ( !$cookie ) {
    return_error( $q,
"Failed to set session cookie.  Make sure all cookies are accepted in your browser"
    );
}

# Send them into the application.
print $q->redirect( -url => "/cgi-bin/main.cgi", -cookie => $cookie );

exit(0);
