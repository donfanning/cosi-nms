#
# $Id$
#
package SAA::Target;

use strict;
require 5.002;
use lib qw(..);    # XXX for testing purposes only.
use SAA::Globals;
use Carp;

sub new {
    my ( $that, @args ) = @_;
    my $class = ref($that) || $that;

    if ( scalar(@args) != 2 ) {
        croak "SAA::Target: Insufficient arguments passed to constructor";
    }

    my $self = {
        name    => $args[0],
        address => undef,
        status  => HOST_UP_IP,
        error   => undef,
    };

    my $addr = gethostbyname( $args[1] );
    $self->{address} = join ( '.', unpack( 'C4', $addr ) );

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

    # This method is divided into a public accessor method, and a protected
    # set method. 
    my $self = shift;
    return $self->{status};
}

sub _status {
    my $self  = shift;
    my $class = ref $self;
    croak "Attempt to call protected method" if ( $class !~ /^SAA::/ );
    $self->{status} = shift;
}

1;
__END__
