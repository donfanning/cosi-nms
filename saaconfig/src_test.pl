#!/usr/bin/perl

use SAA::Source;

my $src = new SAA::Source("nms-comm1", "nms-comm1", "1");
$src->read_community(1, "52616e646f6d49565c0c4b96bf783e7488261dd66c008271");
$src->write_community(0, "private");
print "learn result = " . (($src->learn() == 1) ? "SUCCESS" : "FAILED"), "\n";
if ($src->error()) {
	print "ERROR: " . $src->error(), "\n";
}
print "Source address = " . $src->addr(), "\n";
print "Source status = ";
if ($src->status() == 0 ) {
	print "DOWN";
}
elsif ($src->status() == 1) {
	print "UP_IP_ONLY";
}
elsif ($src->status() == 2) {
	print "UP_SNMP";
}
else {
	print "UNKNOWN";
}
print "\n";

print "SNMP version = " . $src->snmp_version(), "\n";

print "read community = " . $src->read_community(0), "\n";
print "write community = " . $src->write_community(1), "\n";

print "SAA version = " . $src->saa_version(), "\n";
print "IOS version = " . $src->ios_version(), "\n";

my $ref = ref $src;
print $ref, "\n";
