package SAA::Operations::Echo;

use strict;
require 5.002;
use lib qw(../..);
use SNMP;
use SAA::Operations::Globals;

sub new {
	my ($class, @args) = @_;
	
	my %fields = (
		Type => $SAA::Operations::Globals::TYPE_ECHO,
		Protocol => $SAA::Operations::Globals::PROTO_ICMP_ECHO,
		Threshold => 5000,
		Frequency => 60,
		Timeout => 5000,
		Target => '',
		Source => '',
		ToS => 0,
	);
}
