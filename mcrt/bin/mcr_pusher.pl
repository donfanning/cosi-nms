#!/usr/local/bin/perl -w
# ...................oO MCR Pusher Oo......................................
# . FILENAME: mcr_pusher.pl
# . DATE: 20.Mar.2001
# . SYNOPSIS: Inserts records from stdin into the database 'deez' under
# . 	the table 'callrecs'.
# . CAVEATS: You need to manually create the database, then run
# .		mcr_create_table (to.. YOU GUESSED IT!)
# . AUTHOR: Weston Hopkins <wehopkin@cisco.com>
# . REFERENCES:
# .	Jim Leonard: For some of the parsing code.
# . 	Homer Simpsons: For insight into life.
# ...........................................................................
use DBD::mysql;
use DBI;
use Time::localtime;

### CHANGE VARIABLES HERE ##################################################

# Hostname of MySQL server
my $db_hostname = "localhost";	

# Database to create the table in
my  $database = "deez"; 

# Name of the table to insert the callrecords into
my $tablename = "callrecs"; 

# Optional username to connect as.
my $username = ""; 

### You shouldn't need to change anything belong this line #################

my $db;
my %months = (
        "Jan" => "01",
        "Feb" => "02",
        "Mar" => "03",
        "Apr" => "04",
        "May" => "05",
        "Jun" => "06",
        "Jul" => "07",
        "Aug" => "08",
        "Sep" => "09",
        "Oct" => "10",
        "Nov" => "11",
        "Dec" => "12"
);
my $tm = localtime;
my $year = $tm->year+1900; # Calculates the current year.

# Connect to MySQL server
if( $username eq "" ) {
        $db = DBI->connect("DBI:mysql:$database:$db_hostname" );
} else {
        $db = DBI->connect("DBI:mysql:$database:$db_hostname", "$username" );
}

# Creates the table
$db->do("CREATE TABLE IF NOT EXISTS $tablename ( 
	server VARCHAR(32), 
	dso_slot INT, dso_contr INT, dso_chan INT,
	slot INT, port INT,
	call_id CHAR(4),
	user_id VARCHAR(32),
	ip VARCHAR(15),
	calling VARCHAR(32),
	called VARCHAR(32),
	std VARCHAR(16),
	prot VARCHAR(32),
	comp VARCHAR(16),
	init_rx INT,
	init_tx INT,
	rbs INT,
	dpad VARCHAR(32),
	retr VARCHAR(32),
	sq VARCHAR(32),
	snr INT,
	rx_chars INT,
	tx_chars INT,
	rx_ec INT,
	tx_ec INT,
	bad INT,
	timeon INT,
	final_state VARCHAR(32),
	disc_radius VARCHAR(32),
	disc_modem VARCHAR(128),
	disc_local VARCHAR(32),
	disc_remote VARCHAR(32),
	timestamp TIMESTAMP(14) )	");


# Takes line form stdin, parses it, and pushes it to the db
LOOP: while(<>) {
	my $r = $_;
	my $server = "NULL";
	my $dso_slot = "NULL";
	my $dso_contr = "NULL";
	my $dso_chan  = "NULL";
	my $slot = "NULL";
	my $port = "NULL";
	my $call_id = "NULL";
	my $user_id = "NULL";
	my $ip = "NULL";
	my $calling = "NULL";
	my $called = "NULL";
	my $std = "NULL";
	my $prot = "NULL";
	my $comp = "NULL";
	my $init_rx = "NULL";
	my $init_tx = "NULL";
	my $final_rx = "NULL";
	my $final_tx = "NULL";
	my $rbs = "NULL";
	my $dpad = "NULL";
	my $retr = "NULL";
	my $sq = "NULL";
	my $snr = "NULL";
	my $rx_chars = "NULL";
	my $tx_chars = "NULL";
	my $rx_ec = "NULL";
	my $tx_ec = "NULL";
	my $bad = "NULL"; # My Bad!
	my $timeon = "NULL";
	my $final_state = "NULL";
	my $disc_local = "NULL";
	my $disc_remote = "NULL";
	my $disc_radius = "NULL";
	my $disc_modem = "NULL";
	my $timestamp = "NULL";
	my $sql = "NULL";

	# Strip out problematic characters
	$r =~ s#\\##g;
	$r =~ s#'##g;
	$r =~ s#`##g;
	
	if( $r =~ /\S+\s\S+\s\S+\s(\S+)\s/ ) {		# Swerver
		$server = $1;
	} else {
		print "\nError parsing server name. Dropping record($r).";
		next LOOP;
	}
	
	if( $r =~ /DS0 slot\/contr\/chan=(.*?)\, /) {	# DSO
		($dso_slot, $dso_contr, $dso_chan) = split("/", $1);
	}
	
	if(	$r =~ /slot\/port=(.*?)\, / ){	# Slot/Port
		($slot, $port ) = split(  "/", $1 );
	}

	if( $r =~ /call_id=(.*?)\, /){	# Call ID
		$call_id = $1;			
	}
	
	if( $r =~ /userid=(.*?)\, /){	# Luser ID
		$user_id = $1;
	}
	
	if( $r =~ /ip=(.*?)\, / ){	# IP
		$ip = $1;
	}
	
	if( $r =~ /calling=(.*?)\, /){	# Calling
		$calling = $1;
	}
	
	if( $r =~ /called=(.*?)\, /) {	# Called
		$called = $1;

	}
	
	if( $r =~ /std=(.*?)\, /){	# Sexually Transmitted Diesease
		$std = $1;
	}
	
	if( $r =~ /prot=(.*?)\, /){	# Protocol
		$prot = $1;
	}
	
	if(	$r =~ /comp=(.*?)\, /) { # Compression
		$comp = $1;
	}
	
	if( $r =~ /init-rx\/tx b-rate=(.*?)\, /){ # Initial TX/RX Rate 
		($init_rx, $init_tx) = split( "/", $1);
	}
	
	if( $r =~ /finl-rx\/tx b-rate=(.*?)\, /) { # Final TX/RX Rate
		($final_rx, $final_tx) = split( "/", $1);
	}		
	
	if( $r =~ /rbs=(.*?)\, /){	# RBS, whatever the fuck that is
		$rbs = $1;	
	}
	
	if( $r =~ /d-pad=(.*?)\, /){ # ? 
		$dpad = $1;
	}
	
	if( $r =~ /retr=(.*?)\, /){ # Retrains?
		$retr = $1;
	}
	
	if( $r =~ /sq=(.*?)\, / ){ # ?
		$sq = $1;
	}
	
	if( $r =~ /snr=(.*?)\, / ){ # Signal to Noise Ratio
		$snr = $1;
	}
	
	if( $r =~ /rx\/tx chars=(.*?)\, / ){ # TX/RX Characters
		($rx_chars, $tx_chars) = split( "/", $1);
	}
	
	if( $r =~ /rx\/tx ec=(.*?)\, / ){ # Error Correction?
		($rx_ec, $tx_ec) = split( "/", $1 );
	}

	if( $r =~ /bad.*bad=(.*?)\, / ){ # Cham on. -Michael Jackson
		$bad = $1;  # There are 2 bad fields? Why?
	}
	
	if( $r =~ /time=(.*?)\, / ){ # The Timeon
		$timeon = $1;
	}
	
	if( $r =~ /finl-state=(.*?)\, / ) { # Final State
		$final_state = $1;
	}
	
	if( $r =~ /disc\(radius\)=(.*?),/ ) { # Disconnect Reason (Radius)
		$disc_radius = $1;		

	}
	
	if( $r =~ /disc\(local\)=(.*?),/ ) { # Disconnect Reason (Local)
		$disc_local = $1;
	}

	if( $r =~ /disc\(modem\)=(.*?)$/ ) { # Disconnect Reason (Modem)
		$disc_modem = $1;
	}

	
	if( $r =~ /disc\(remote\)=(.*)/ ) { # Disconnect Reason (Remote)
		$disc_remote = $1;
	}

	my $i;
	foreach $i ($dso_slot, $dso_chan, $dso_contr, $slot, $port, $timeon,
		$init_rx, $init_tx, $snr, $tx_chars, $rx_chars, $tx_ec, $rx_ec,
		$bad, $timeon, $rbs ) {
		if( $i ) {
			if ($i =~ /\D/ ) {
				if( !($i eq "NULL" )) {
#					print "\n$i isn't valid in this line: ($r).";
					next LOOP;
				}
			}
		}
	}
	
	# Parses and converts the timestamp to MySQL format
	my ($month, $day, $time, $hour, $minute, $second );
	($month, $day, $time) = split(' ', substr( $r, 0, 15 ) );
	if( $month && $day && $time ) {
		$month = $months{$month}; # Converts month to number
	} else {
		print "\nError with time ($r).";
		next LOOP;
	}
	($hour, $minute, $second ) = split( ':', $time );
	if( $hour && $minute && $second ) {
		$timestamp = "$year$month$day$hour$minute$second";
	} else {
		print "\nError with time ($r).";
		next LOOP;
	}

	if( $timestamp =~ /\D/ ) {
		print "\nError with timestamp. Dropping record ($r).";
		next LOOP;
	} 

	# This is ugly... Inserts the vars into the db.
	$sql = "\nREPLACE into $tablename VALUES ( \'$server', $dso_slot, $dso_contr, $dso_chan, $slot, $port, '$call_id', '$user_id', '$ip', '$calling', '$called', '$std', '$prot', '$comp', $init_rx, $init_tx, $rbs, '$dpad', '$retr', '$sq', $snr, $rx_chars, $tx_chars, $rx_ec, $tx_ec, $bad, $timeon, '$final_state', '$disc_radius', '$disc_modem', '$disc_local', '$disc_remote', $timestamp );";
	$db->do($sql);
	if( $db->errstr ) {
		print "\n{$r}";
	}

#	print $sql;
}
$db->disconnect();
