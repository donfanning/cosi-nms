#!/usr/bin/perl
# a script to test Collector.pm by installing a simple Echo Operation
# note that this automatically tests SAA:Source, SAA:Target, and SAA:Operation
#use SAA::Source;
#use SAA::Collector;
#use SAA::Target;
#use SAA::Operation;
#use SAA::SAA_MIB;
$|++;
print "----------------------------\n";

#----SAAa::Source------#
#---value init---#
$name   = 'test_config';
$src_IP = shift || '10.5.1.14';
$dst_IP = shift || '172.18.123.229';

#---value initend--#

$src = SAA::Source->new( "2600_rtr_src", $src_IP, "2c" );
$src->read_community( 0,  "public" );
$src->write_community( 0, "private" );

die "ERR: $src->error()" unless ( $src->learn() );
if ( $src->error() ) {
    print "ERROR: " . $src->error(), "\n";
}

print "Source status = ";
if ( $src->status() == 0 ) {
    $status = "DOWN";
}
elsif ( $src->status() == 1 ) {
    $status = "UP_IP_ONLY";
}
elsif ( $src->status() == 2 ) {
    $status = "UP_SNMP";
}
else {
    $status = "UNKNOWN";
}
print "Source \("
  . $src->addr()
  . "\) learnt, $status, SAA version: "
  . $src->saa_version()
  . ", IOS version: "
  . $src->ios_version() . "\n";

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

    #print $$supportedTypes{$_}, ", ";
}
print "\n";

print "----------------------------\n";

#----SAA::Operation----#
#---value init---#
$oper_type = '1';
my %operationTypeEnum_rev = reverse %$operationTypeEnum;

#RttMonRttType ::= TEXTUAL-CONVENTION
#..
#    echo(1),  <------
#    pathEcho(2),
#    fileIO(3),

$oper_proto = '2';
my %operationProtocolEnum_rev = reverse %$operationProtocolEnum;

#RttMonProtocol ::= TEXTUAL-CONVENTION
#..
#    notApplicable(1),
#    ipIcmpEcho(2), <-----
#    ipUdpEchoAppl(3),
#---value initend---#

die "ERR: $!"
  unless ( $oper = SAA::Operation->new( "op_type", $oper_type, $oper_proto ) );

#need to define a SAA::Operation::error()
#letting timeout, freq and threshold take on defaults
print "Operation \("
  . $oper->name()
  . "\), type: "
  . $operationTypeEnum_rev{ $oper->type() }
  . " protocol: "
  . $operationProtocolEnum_rev{ $oper->protocol() } . "\n";

#also may need to change icmpEcho in SAA::MIB to ipIcmpEcho (as per mib)

print "----------------------------\n";

#----SAA::Target-----#
$dst = SAA::Target->new( "dst_2600_rtr", $dst_IP );

# there might need to have an explicit check on the status of destIP
# before declaring it as HOST_UP_IP. still i'll use the status() here:
#note: no need to set target, but settting it just for the heck of it
print "destination \($dst_IP\) status: " . $dst->status() . "\n";

print "----------------------------\n";

#----SAA::Collector---#
#--Value init.--#
$nvram_truthvalue = '1';    # sets TruthValue in rttMonCtrlAdminNvgen to 1

$history_filter = '2';

#rttMonHistoryAdminFilter OBJECT-TYPE
#    none(1),
#    all(2), <------
#    overThreshold(3),
#    failures(4)

$life = '360';              # life of the Row would be 3 hrs
$start_time = '1'; # using special value of rttMonScheduleAdminRttStartTime here

#note; i think code in the collector would be needed to be added for 
#supporting $start_times as actual timeticks + some lead time before 
#starting the data collection
# a possible way could be to poll the sysUptime (in ticks) 
#and use that to come up with the offset to current time that the 
#--Value init.end--#
#no need to test $collectur->id() as that is used by the install(xx) method.
# i think $collectur->id() should be a private method for Collector.pm

$collectur = SAA::Collector->new( $name, $src, $oper, $dst );
$collectur->write_nvram($nvram_truthvalue);

#forcing it to write mem so i can check if rtrs config changes at install()
$collectur->history_filter($history_filter);
$collectur->life($life);
$collectur->start_time($start_time);
print "ID: " . $collectur->id() . "\n";

#and ladies and gentlemen...
print "Installing SA Agent on Source router...";
$collectur->install();
print "completed\n";

print( "ERR: " . $collectur->error . "\n" ) if ( $collectur->error() );

#print "rowID: $collectur->id(), NVRAM_write: $collectur->write_nvram, history: $collectur->history_filter() \n";
#print "life: $collectur->life(), start_time: $collectur->start_time(), any_error: $collectur->error() \n";

