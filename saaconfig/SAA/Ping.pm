package SAA::Ping;

BEGIN { $ENV{'PATH'} = '/bin:/sbin:/usr/bin:/usr/sbin'; }

use strict;
require 5.002;

use vars qw(@EXPORT_OK);

use Exporter;
use Carp;

*import    = \&Exporter::import;
@EXPORT_OK = qw(saa_ping);

use vars qw($PING $PING_OPTIONS $REDIRECT);

$PING         = '/sbin/ping';
$PING_OPTIONS = '-c 1';                          # Stop pinging after one packet
$REDIRECT     = '2>&1 >/dev/null';
$REDIRECT     = '> nul' if ( $^O eq "Win32" );

sub saa_ping {
    my $addr = shift;

    return 0 unless defined $addr;

    my $result =
      system( $PING . " " . $PING_OPTIONS . " " . $addr . " " . $REDIRECT );

    return 0 if $result;

    1;
}

1;
__END__
