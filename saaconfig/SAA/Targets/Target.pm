package SAA::Targets::Target;

use strict;
require 5.002;
use lib qw(../..);
use SAA::Globals;
use SAA::Ping;

sub new {
    my ( $that, @args ) = @_;
    my $class = ref($that) || $that;

    my $self = {
        Name    => undef,
        Address => undef,
        Status  => $SAA::Globals::HOST_UP_IP,
    };

    bless( $self, $class );
    $self->name( $args[0] );
    $self->addr( $args[1] );
    $self;
}

use Alias qw(attr);
use vars qw($Name $Address $Status);

sub name {
    my $self = attr shift;
    if (@_) { $Name = shift; }
    return $Name;
}

sub addr {
    my $self = attr shift;
    if (@_) { $Address = shift; }
    return $Address;
}

sub status {

    # This method is divided into a public accessor method, and a private
    # set method. 
    my $self = attr shift;
    return $Status;
}

sub _status {
    my $self = attr shift;
    $Status = shift;
}

sub test {

    # This method tests for connectivity to the target.  This is _not_ run
    # automatically.  By default, all hosts are said to be reachable via
    # IP since they may not _really_ be reachable from the management
    # station.
    my $self = attr shift;
    return 0 unless defined $self->addr();

    if ( !saa_ping( $self->addr() ) ) {
        $self->_status($SAA::Globals::HOST_DOWN);
    }
    else {
        $self->_status($SAA::Globals::HOST_UP_IP);
    }

    1;
}

1;
__END__
