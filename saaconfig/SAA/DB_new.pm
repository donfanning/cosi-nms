package SAA::DB;

use strict;
require 5.002;
use lib qw(..);
use DBI;
use Carp;

use vars qw(
  $TBL_SOURCE
  $TBL_TARGET
  $TBL_OPERATION
  $TBL_COLLECTOR
  $TBL_USER
  %objectToGetMethod
);

$TBL_SOURCE    = 'SAA_SOURCES';
$TBL_TARGET    = 'SAA_TARGETS';
$TBL_OPERATION = 'SAA_OPERATIONS';
$TBL_COLLECTOR = 'SAA_COLLECTOR';
$TBL_USER      = 'SAA_USERS';

%objectToGetMethod = (
    'SAA::Source'    => \&_get_source,
    'SAA::Target'    => \&_get_target,
    'SAA::Operation' => \&_get_operation,
    'SAA::Collector' => \&_get_collector,
    'SAA::User'      => \&_get_user,
);

sub new {
    my ( $that, @args ) = @_;
    my $class = ref($that) || $that;

    if ( scalar(@args) != 4 ) {
        croak "SAA::DB: Insufficient arguments passed to constructor";
    }

    my $self = {
        dbh   => undef,
        error => undef,
    };

    $self->{dbh} =
      DBI->connect( 'dbi:' . $args[0] . ':' . $args[1], $args[2], $args[3] )
      or croak "SAA::DB: Unable to connect to database " . $args[1];

    bless( $self, $class );
    $self;
}

sub dbh {

    # Allow external callers access to the raw database handle.  If they want
    # to run raw queries, they're welcome to.
    my $self = shift;
    return $self->{dbh};
}

sub error {
    my $self = shift;
    if (@_) { $self->{error} = shift; }
    return $self->{error};
}

sub get_object {
    my $self = shift;

    if ( scalar(@_) < 1 ) {
        croak "DB::get_object: Must specify at least one argument";
    }

    my $obj = shift;
    if ( !$objectToGetMethod{$obj} ) {
        croak "DB::get_object: Unknown object, $obj";
    }

    # This can be confusing.  We're using the static hash to map an object to
    # a method.  We pass the remaining get_object arguments to this private
    # method.
    my $method = $objectToGetMethod{$obj};
    return $self->$method(@_);
}

sub _get_source {
    my $self  = shift;
    my $class = ref $self;
    croak "Attempt to call private method" if ( $class ne __PACKAGE__ );
    my ( $query, $dbh, $sth, $src, $srcs );

    $query = "SELECT * FROM $TBL_SOURCE";
    $dbh   = $self->dbh();

    if (@_) {

        # Arguments have been passed.  Use the arguments to build SQL queries.
        $query .= " WHERE ";
        my $arg;
        my %args = @_;
        foreach $arg ( keys %args ) {

            # Handle LIKE '%string%' queries.
            if ( $args{$arg} =~ /[^\\]%/ ) {
                $query .= "$arg LIKE '$args{$arg}',";
            }
            else {
                $query .= "$arg='$args{$arg}',";
            }
        }
        $query =~ s/,$//;
    }

    if ( !( $sth = $dbh->prepare($query) ) ) {
        $self->error( "Failed to prepare query: " . $dbh->errstr() );
        return;
    }

    if ( !( $sth->execute() ) ) {
        $self->error( "Failed to execute query: " . $dbh->errstr() );
        return;
    }

    my $row;
    while ( $row = $sth->fetchrow_hashref() ) {

        $src =
          new SAA::Source( $row->{Name}, $row->{Address},
            $row->{SNMP_Version} );
        $src->read_community( $row->{Read_Community} );
        $src->write_community( $row->{Write_Community} );
        $src->_saa_version( $row->{SAA_Version} );
        $src->_ios_version( $row->{IOS_Version} );
        $src->_status( $row->{Status} );
        my ( $type, $protocol );

        foreach $type ( split ( /;/, $row->{Supported_Types} ) ) {
            $src->_add_type_supported($type);
        }
        foreach $protocol ( split ( /;/, $row->{Supported_Protocols} ) ) {
            $src->_add_protocol_supported($protocol);
        }
        push @{$srcs}, $src;
    }

    $sth->finish();

    return $srcs;
}

sub _get_target {
    my $self  = shift;
    my $class = ref $self;
    croak "Attempt to call private method" if ( $class ne __PACKAGE__ );
    my ( $query, $dbh, $sth, $target, $targets );

    $query = "SELECT * FROM $TBL_TARGET";
    $dbh   = $self->dbh();

    if (@_) {

        # Arguments have been passed.  Use the arguments to build SQL queries.
        $query .= " WHERE ";
        my $arg;
        my %args = @_;
        foreach $arg ( keys %args ) {

            # Handle LIKE '%string%' queries.
            if ( $args{$arg} =~ /[^\\]%/ ) {
                $query .= "$arg LIKE '$args{$arg}',";
            }
            else {
                $query .= "$arg='$args{$arg}',";
            }
        }
        $query =~ s/,$//;
    }

    if ( !( $sth = $dbh->prepare($query) ) ) {
        $self->error( "Failed to prepare query: " . $dbh->errstr() );
        return;
    }

    if ( !( $sth->execute() ) ) {
        $self->error( "Failed to execute query: " . $dbh->errstr() );
        return;
    }

    my $row;
    while ( $row = $sth->fetchrow_hashref() ) {

        $target =
          new SAA::Target( $row->{Name}, $row->{Address});
        $target->_status( $row->{Status} );
        push @{$targets}, $target;
    }

    $sth->finish();

    return $targets;
}


sub DESTROY {
    my $self = shift;

    # We create an explicit DESTROY method to take care of closing the 
	# database handle.
	$self->dbh()->commit();
    $self->dbh()->disconnect();
}
