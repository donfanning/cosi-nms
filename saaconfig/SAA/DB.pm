package SAA::DB;

# oansari 2.11.2002: adding required methods: add_source
#notes: need to populate self->error and return gracefully, instead of dying arbitrarily in methods

use strict;
require 5.002;
use lib qw(..);
use conf::prefs qw($DB_DRIVER $DB_USER $DB_PASS $DB_NAME);
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

    #creating a new object of this class merely connects to the saaconf db,
    #and returns the dbh handle.
    my ( $that, @args ) = @_;
    my $class = ref($that) || $that;

    my $self = {
        dbh   => undef,
        error => undef,
    };

    $self->{dbh} =
      DBI->connect( 'dbi:' . $DB_DRIVER . ':' . $DB_NAME, $DB_USER, $DB_PASS )
      or croak "SAA::DB: Unable to connect to database " . $DB_NAME;

    bless( $self, $class );
    $self;
}

sub dbh {

    # Allow external callers access to the raw database handle.  If they want
    # to run raw queries, they're welcome to.
    #doing nothing but returning the dbh handle created after the object has been
    #instantiated.
    my $self = shift;
    return $self->{dbh};
}

sub add_source {

    #This public method would let callers enter a source in the table SAA_SOURCES
    #Note: this does NOT make changes to already defined source (see &modify_source)
    #Takes in the following vars in the respective order:
    #SrcAlias, SrcIpAddr, SrcDescr, SrcHostname, SrcReadComm, SrcWriteComm, SrcSnmpVersion, 
    #SrcIosVersion, SrcRttAppVersion, SrcSupportedProtocols
    use vars
      qw ($SrcAlias $SrcIpAddr $SrcDescr $SrcHostname $SrcReadComm $SrcWriteComm $SrcSnmpVersion $SrcIosVersion $SrcRttAppVersion @SrcSupportedProtocols @ary @IDs @Vals $sth);

    #note: see conf::tables.pm for hints on schema. do note: if some of the vars 
    #above are not specified by user during configuration, the calling party needs 
    #to still pass _undef_ instead of that var

    #also note that SrcSupportedProtocols is an array not a scalar.
    my $self = shift;
    my @args = shift;
    my $dbhx = $self->{dbh};
    die "Insufficient args passed to add_source()" if ( scalar(@args) < 10 );
    (
      $SrcAlias,       $SrcIpAddr,     $SrcDescr,
      $SrcHostname,    $SrcReadComm,   $SrcWriteComm,
      $SrcSnmpVersion, $SrcIosVersion, $SrcRttAppVersion,
      @SrcSupportedProtocols
      )
      = @args;
    die "SrcAlias needs to be defined"  if ( $SrcAlias  eq "_undef_" );
    die "SrcIpAddr needs to be defined" if ( $SrcIpAddr eq "_undef_" );

    my %SrcValHash = (
        SrcId                 => undef,
        SrcAlias              => $SrcAlias,
        SrcIpAddr             => $SrcIpAddr,
        SrcDescr              => $SrcDescr,
        SrcHostname           => $SrcHostname,
        SrcReadComm           => $SrcReadComm,
        SrcWriteComm          => $SrcWriteComm,
        SrcSnmpVersion        => $SrcSnmpVersion,
        SrcIosVersion         => $SrcIosVersion,
        SrcRttAppVersion      => $SrcRttAppVersion,
        SrcSupportedProtocols => @SrcSupportedProtocols
      );

      #check to see if src already exists and if it does, then balk out.
      my $selector =
"select \* from SAA_SOURCES where SrcIpAddr=\"$SrcIpAddr\" or SrcAlias=\"$SrcAlias\"";
    die
"DB.pm : SrcAlias and.or SrcIpAddr of this source is already present: @ary"
      if ( scalar( @ary = $dbhx->selectrow_array($selector) ) != 0 );

      undef @ary;

    #everything looks good, so let's insert this source into database:
    #first, lets churn up the next available SrcId
    my $srcidchecker = "select \* from  SAA_SOURCES order by SrcId DESC";
    if ( scalar( @ary = $dbhx->selectrow_array($srcidchecker) ) != 0 ) {
        $SrcValHash{SrcId} = "0";
    }
    else {
        $SrcValHash{SrcId} = ++$ary[0];
    }

    my $key;
    foreach $key ( keys %SrcValHash ) {
        if ( "$SrcValHash{$key}" ne "_undef_" ) {

            #this is to get rid of all the vars not defined by user, 
            #so we dont bother inserting them into the table
            push ( @IDs,  $key );
            push ( @Vals, "\"$SrcValHash{$key}\"" );

            #this can be tricky business for @SrcSupportedProtocols
        }
    }

    my $IDs  = join ( ',', @IDs );
    my $Vals = join ( ',', @Vals );

    my $inserter = "insert into SAA_SOURCES \($IDs\) VALUES \($Vals\)";

    if ( !($sth = $dbhx->prepare($inserter) ) ) {
        $self->error( "Failed to prepare query: " . $dbhx->errstr() );
        return;
    }

    if ( !( $sth->execute() ) ) {
        $self->error( "Failed to execute query: " . $dbhx->errstr() );
        return;
    }
}

sub error {

    #this populates the error() value for the object (if there is something STDIN
    #regardless, it eventually churns out the error message as a return.
    my $self = shift;
    if (@_) { $self->{error} = shift; }
    return $self->{error};
}

sub get_object {

    #this provides a public method to make calls on private methods 
    #like _get_source to keep a level of database integrity
    #thus, it is anticipating the pointer to the function name,
    #and the arguments to be passed to this function name.
    #anticipating something like :
    # get_object('SAA::Source', select args...)
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

    # create SELECT SQL queries on $SRC_TABLE and deliver result
    # see question1 below:
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

    #finally get data back using fetchrow_hashref()
    # question1 : why are we creating a source again with this data that was ingested in the DB?
    # the data was ingested by creating a source in the first place...

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

    #creates SELECT statmentes to be executed on $TBL_TARGET
    #question2 : same as question1
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

        $target = new SAA::Target( $row->{Name}, $row->{Address} );
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
