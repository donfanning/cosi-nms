package SAA::Ping;

use strict;
require 5.002;

use vars qw(@EXPORT_OK);

use Exporter;
use Carp;

*import    = \&Exporter::import;
@EXPORT_OK = qw(saa_ping);

use vars qw(@PING $PING_OPTIONS $REDIRECT);

# XXX We should check to see which ping to use.  On Windows, there is only one
# real choice.  On UNIX, however, ping could reside in a variety of places.
# It's not safe just to say "ping".  One might think it's better to use
# Net::Ping, but ICMP sockets require root privilege on UNIX.  If someone can
# find a better solution than this, feel free to code it.
if ( $^O eq "MSWin32" ) {
    @PING = ('ping');
}
else {
    @PING = ( '/sbin/ping', '/usr/sbin/ping' );
}
# XXX These options should probably be OS (or platform) dependent.
# HP-UX uses -n for count.
$PING_OPTIONS = '-c 1';                          # Stop pinging after one packet
$REDIRECT     = '2>&1 >/dev/null';
$REDIRECT     = '> nul' if ( $^O eq "MSWin32" );

sub saa_ping {
    my $addr = shift;
    my $ping = "";

    return 0 unless defined $addr;

    if ( $^O eq "MSWin32" ) {
        $ping = $PING[0];
    }
    else {
        foreach (@PING) {
            if ( -x $_ ) {
                $ping = $_;
                last;
            }
        }
    }

    return 0 unless $ping;

    my $result =
      system( $ping . " " . $PING_OPTIONS . " " . $addr . " " . $REDIRECT );

    return 0 if $result;

    1;
}

1;
__END__
