#!/usr/bin/perl

use lib qw(/home/marcus/src/saa);
use SAA::Sources::Source;

my $src = new SAA::Sources::Source("creme-brulee", "192.168.1.1", "1");
$src->community(1, "83bbbbdcc6211844", 6);
print $src->learn(), "\n";
print $src->addr(), "\n";
print $src->status(), "\n";

print $src->community(1), "\n";
print $src->comm_length(), "\n";
