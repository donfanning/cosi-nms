#!/usr/bin/perl
# knail1 2.13.2002: script to test SAA::DB
use SAA::Source;
use SAA::DB;
$src_IP = shift || '10.5.1.15';
my $src = new SAA::Source( "no_such_name", '10.5.1.15', "2c" );
$src->read_community( 0,  public );
$src->write_community( 0, "private" );
print "learn result = " . ( ( $src->learn() == 1 ) ? "SUCCESS" : "FAILED" ),
  "\n";

if ( $src->error() ) {
    print "ERROR: " . $src->error(), "\n";
}
print "Source address = " . $src->addr(), "\n";
print "Source status = ";
if ( $src->status() == 0 ) {
    print "DOWN";
}
elsif ( $src->status() == 1 ) {
    print "UP_IP_ONLY";
}
elsif ( $src->status() == 2 ) {
    print "UP_SNMP";
}
else {
    print "UNKNOWN";
}
print "\n";

print "SNMP version = " . $src->snmp_version(), "\n";

print "read community = " . $src->read_community(0),   "\n";
print "write community = " . $src->write_community(0), "\n";

print "SAA version = " . $src->saa_version(), "\n";
print "IOS version = " . $src->ios_version(), "\n";

my $supportedProtocols = $src->protocol_supported();
print "Supported protocols: ";
foreach ( keys %{$supportedProtocols} ) {
    print $_, " ";
}
print "\n";

my $supportedTypes = $src->type_supported();
print "Supported types: ";
foreach ( keys %{$supportedTypes} ) {
    print $_, " ";
}
print "\n-----------\n";

print "ingesting into database:\n";

$dbh = new SAA::DB();

if ( !( $dbh->add_source($src) ) ) {
    print "couldn't add source: " . $dbh->error . "\n ";
}
else { print "source added successfully\n" }
