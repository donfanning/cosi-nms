package SAA::User;


use strict;
require 5.002;
use Carp;
use vars qw(@ISA @EXPORT_OK %EXPORT_TAGS);
use Exporter;
use Carp;
use Digest::MD5 qw(md5_hex);
use lib qw(..);

@ISA       = qw(Exporter);
@EXPORT_OK = qw(
    PERMS_GUEST
    PERMS_USER
    PERMS_ADMIN
);
%EXPORT_TAGS = (Perms => [qw(PERMS_GUEST PERMS_USER PERMS_ADMIN)],);

use constant PERMS_GUEST => 0x00;
use constant PERMS_USER  => 0x80;
use constant PERMS_ADMIN => 0xFF;

sub new {
        my ($that, @args) = @_;
        my $class = ref($that) || $that;

        if (scalar(@args) != 1) {
                croak "SAA::User: Insufficient arguments passed to constructor";
        }

        my $self = {
                username  => $args[0],
                password  => undef,
                firstname => undef,
                lastname  => undef,
                perms     => PERMS_GUEST,
        };

        bless($self, $class);
        $self;
}

sub username {
        my $self = shift;
        return $self->{username};
}

sub password {
        my $self = shift;

        if (@_) {

                # Store the password as a MD5 hash in memory
                # and in the database
                my $pass = shift;
                $self->{password} = md5_hex($pass);
        }

        return $self->{password};
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
                if ($perms < PERMS_GUEST || $perms > PERMS_ADMIN) {
                        croak
                            "SAA::User::perms: Invalid user permissions: $perms";
                }
                $self->{perms} = $perms;
        }
        return $self->{perms};
}

sub validate_passwd {
        my $self = shift;

        if (@_) {
                my $check_pass = shift;
                if (md5_hex($check_pass) ne $self->password()) {
                        return;
                }
        } else {
                if ($self->password()) {
                        return;
                }
        }

        1;
}

1;
