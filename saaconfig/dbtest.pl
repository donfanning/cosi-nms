#!/usr/bin/perl
BEGIN { push ( @INC, "/home/nicko/saaconfig" ); };

use SAA::DB;
use SAA::Source;
use SAA::Target;
use SAA::Operation;

$db = SAA::DB->new( 
					Database => "localhost",
					Driver	 => "mysql",
					);

print "setSAAObject:\n";

$sourceObj = SAA::Source->new( "Sources", "10.1.1.1", "1" );
$targetObj = SAA::Target->new( "Targets", "10.1.1.2" );
$operationObj = SAA::Operation->new("Operations",$SAA::Operation::TYPE_ECHO,$SAA::Operation::PROTO_ICMP_ECHO);

print "Source Object created\n";

print "Info From source\n";

$blah  = $db->setSAAObject( $sourceObj );
$blah2 = $db->setSAAObject( $targetObj );
$blah3 = $db->setSAAObject( $operationObj );

print "BLAH $blah\n";
print "BLAH2 $blah2\n";
