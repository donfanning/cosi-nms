#!/usr/bin/perl -wT

use strict;
require 5.002;
use CGI;
use CGI::Carp qw(fatalsToBrowser);
use lib "..";
use SAA::CGI;

$| = 1;

my $q = new CGI();
if ( session_start($q) ) {
    session_destroy($q);
}

print $q->location( -url => "/index.html" );
