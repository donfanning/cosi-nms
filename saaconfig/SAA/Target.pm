package SAA::Target;

use strict;
require 5.002;
use lib qw(..);
use SAA::Globals;

sub new {
    my ( $that, @args ) = @_;
    my $class = ref($that) || $that;

    if ( scalar(@args) != 2 ) {
		return;
    }

    my $self = {
        name    => $args[0],
        address => $args[1],
        status  => $SAA::Globals::HOST_UP_IP,
    };

    bless( $self, $class );
    $self;
}

sub name {
    my $self = shift;
    if (@_) { $self->{name} = shift; }
    return $self->{name};
}

sub addr {
    my $self = shift;
    if (@_) { $self->{address} = shift; }
    return $self->{address};
}

sub status {

    # This method is divided into a public accessor method, and a private
    # set method. 
    my $self = shift;
    return $self->{status};
}

sub _status {
    my $self = shift;
    $self->{status} = shift;
}

1;
__END__
