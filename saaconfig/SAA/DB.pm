package SAA::DB;

use strict;
require 5.002;
use DBI;
use Carp;

sub new {
	
	my ($that, @args) = @_;
	my $class = ref($that) || $that;
	my %params = @args;
	my $self = {
		Driver 		=> $params{Driver},
		Database 	=> $params{Database},
		Hostname 	=> $params{Hostname},
		User		=> $params{User},
		Password	=> $params{Password},
		dbh			=> undef;
	};
	
	# Create connect to database.
	$dbh = DBI->connect (
			"DBI:$self{'Driver'}:$self{'Datbase'}:$self{'Hostname'}",
			$self{'User'},
			$self{'Password'}
			);
	
	bless ($self, $class);

}

sub driver {
	my $self = shift;
	if (@_) {$self->{Driver} = shift;}
	return $self->{Driver};
}

sub database {
	my $self = shift;
	if (@_) {$self->{Database} = shift;}
	return $self->{Database};
}

sub hostname {
	my $self = shift;
	if (@_) {$self->{Hostname} = shift;}
	return $self->{Hostname};
}

sub user {
	my $self = shift;
	if (@_) {$self->{User} = shift;}
	return $self->{User};
}
sub password {
	my $self = shift;
	if (@_) {$self->{Password} = shift;}
	return $self->{Password};
}

sub getSAAObject {
	my $self = shift;

	if (!@_) {
		
		croak "SAA::DB: No defaults for sub please specify\n\tgetSAAObject(Tablename, name => value)\n";
	}

	my $table = shift;
	my %name = @_;
	my $key;
	foreach $key (keys %name) {
		print "Key: $key Value: $name{$key}\n";
	}
	print "--Database stuff--\n";
	print "Database: " . $self->database() . " \n";
}
