package SAA::User;

use strict;
require 5.002;
use Carp;
use vars qw(@ISA @EXPORT);
use Exporter;
use Carp;
use Crypt::CBC;
use lib qw(..);
use conf::prefs qw(KEY);

@ISA    = qw(Exporter);
@EXPORT = qw(
  PERMS_GUEST
  PERMS_USER
  PERMS_ADMIN
);

use constant PERMS_GUEST => 0x00;
use constant PERMS_USER  => 0x80;
use constant PERMS_ADMIN => 0xFF;

sub new {
    my ( $that, @args ) = @_;
    my $class = ref($that) || $that;

    if ( scalar(@args) != 1 ) {
        croak "SAA::User: Insufficient arguments passed to constructor";
    }

    my $self = {
        username  => $args[0],
        password  => undef,
        firstname => undef,
        lastname  => undef,
        perms     => PERMS_GUEST,
    };

    bless( $self, $class );
    $self;
}

sub username {
    my $self = shift;
    return $self->{username};
}

sub password {
    my $self      = shift;
    my $encrypted = 0;
    $encrypted = shift if (@_);

    if (@_) {

        # Store the password in a Blowfish cipher in memory
        # and in the database
        my $pass = shift;
        if ($encrypted) {
            $self->{password} = $pass;
            return $self->{password};
        }
        my $cipher = new Crypt::CBC( KEY, 'Crypt::Blowfish' );

        $self->{password} = $cipher->encrypt_hex($pass);
    }

    if ($encrypted) {
        return $self->{password};
    }
    my $cipher = new Crypt::CBC( KEY, 'Crypt::Blowfish' );
    my $pass = $cipher->decrypt_hex( $self->{password} );

    return $pass;
}

sub firstname {
    my $self = shift;
    if (@_) { $self->{firstname} = shift; }
    return $self->{firstname};
}

sub lastname {
    my $self = shift;
    if (@_) { $self->{lastname} = shift; }
    return $self->{lastname};
}

sub perms {
    my $self = shift;
    if (@_) {
        my $perms = shift;
        if ( $perms < PERMS_GUEST
            || $perms > PERMS_ADMIN )
        {
            croak "SAA::User::perms: Invalid user permissions: $perms";
        }
        $self->{perms} = $perms;
    }
    return $self->{perms};
}

1;
