package SAA::Targets::Target;

use strict;
require 5.002;
use lib qw(../..);
use SAA::Globals;
# Is this still a valid Package?
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

1;
__END__
