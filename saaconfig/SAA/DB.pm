#
# $Id$
#
package SAA::DB;

use strict;
require 5.002;
use DBI;
use SAA::Globals;
use SAA::SAA_MIB;
use Carp;

sub new {

    my ( $that, @args ) = @_;
    my $class = ref($that) || $that;
    my %params = @args;
    my $self   = {};
    $self = {
        Driver   => $params{Driver},
        Database => $params{Database},
        Hostname => $params{Hostname},
        User     => $params{User},
        Password => $params{Password},
        error    => undef,
        dbh      => undef
    };

    # Create connect to database.
    my $DSN = "DBI:" . $self->{Driver} . ":";
    $DSN = $DSN . $self->{Database} . ":";
    $DSN = $DSN . $self->{Hostname};

    #		my $dbh = DBI->connect (
    #    			$DSN,
    #    			$self->{User},
    #    			$self->{Password}
    #    			);

    bless( $self, $class );
    $self;

}

sub driver {
    my $self = shift;
    if (@_) { $self->{Driver} = shift; }
    return $self->{Driver};
}

sub database {
    my $self = shift;
    if (@_) { $self->{Database} = shift; }
    return $self->{Database};
}

sub hostname {
    my $self = shift;
    if (@_) { $self->{Hostname} = shift; }
    return $self->{Hostname};
}

sub user {
    my $self = shift;
    if (@_) { $self->{User} = shift; }
    return $self->{User};
}

sub password {
    my $self = shift;
    if (@_) { $self->{Password} = shift; }
    return $self->{Password};
}

sub error {
    my $self = shift;
    if (@_) { $self->{error} = shift; }
    return $self->{error};
}

# XXX This object will create a INSERT Statment and apply it 
# to the database.  At this point it simply prints the query.

sub setSAAObject {
    my $self = shift;
    my $obj  = shift;
    my $ref  = ref $obj;
    my $table;

    if ( $ref eq "SAA::Source" ) {

        $table = "Sources";
    }

    elsif ( $ref eq "SAA::Target" ) {

        $table = "Targets";
    }

    elsif ( $ref eq "SAA::Operation" ) {

        $table = "Operations";
    }

    elsif ( $ref eq "SAA::Collector" ) {

        $table = "Collectors";
    }

    else {

        croak
          "SAA::DB->setSAAObject: $ref is not a valid object for this method.";
    }

    if ( !$obj ) {

        croak "SAA::DB->setSAAObject: Can't find a valid object for $table";
    }

    if ( $table eq "Sources" ) {
        my $query =
"INSERT INTO $table (Name,Address,SNMPVer,SAAVer,IOSVer,Status,readCommunity,writeCommunity) values ('";
        $query = $query . $obj->name . "','";
        $query = $query . $obj->addr . "','";
        $query = $query . $obj->snmp_version . "','";
        $query = $query . $obj->saa_version . "','";
        $query = $query . $obj->ios_version . "','";
        $query = $query . $obj->status . "','";
        $query = $query . $obj->read_community . "','";
        $query = $query . $obj->write_community . "')";

        print "$table Query: $query\n";
    }

    if ( $table eq "Targets" ) {

        my $query = "INSERT INTO $table (Name,Address,Status) values ('";
        $query = $query . $obj->name . "','";
        $query = $query . $obj->addr . "','";
        $query = $query . $obj->status . "')";

        print "$table Query: $query\n";
    }

    if ( $table eq "Operations" ) {

        my $query =
"INSERT INTO $table (Name,Type,Protocal,Threshold,Timeout,Frequency,TOS,sourcePort,targetPort,controlEnabled) values ('";
        $query = $query . $obj->name . "','";
        $query = $query . $obj->type . "','";
        $query = $query . $obj->protocol . "','";
        $query = $query . $obj->threshold . "','";
        $query = $query . $obj->timeout . "','";
        $query = $query . $obj->frequency . "','";
        $query = $query . $obj->tos . "','";
        $query = $query . $obj->sourcePort . "','";
        $query = $query . $obj->targetPort . "','";
        $query = $query . $obj->control_enabled . "')";

        print "$table Query: $query\n";

    }

    if ( $table eq "Collectors" ) {

        # XXX Not to sure about this one. Because I have no module
        # to go off of here.
        # if we are going to use this function then we need to create a 
        # Collectors object. (Maybe we can sell it on Ebay)

        my $query =
	"INSERT INTO $table (Name,ID,sourceName,targetName,operationName,startTime,Life,NVRam,historyFilter) values ('";
        $query = $query . $obj->name . "','";
        $query = $query . $obj->id . "','";
        $query = $query . $obj->source . "','";
        $query = $query . $obj->target . "','";
        $query = $query . $obj->operation . "','";
        $query = $query . $obj->startTime . "','";
        $query = $query . $obj->life . "','";
        $query = $query . $obj->writeNVRAM . "','";
        $query = $query . $obj->historyFilter . "')";

        print "$table Query: $query\n";

    }

}
# This method will actually return a object created from the database
# Give it a table name to represent the type of object to create.
# and give it a name to find the correct object.
sub getSAAObject {
    my $self = shift;

    if ( !@_ ) {

        croak
"SAA::DB: No defaults for sub please specify\n\tgetSAAObject(Tablename, name => value)\n";
    }

    my $table = shift;
    my $name  = @_;
    my $key;
    my $query = "SELECT * FROM $table WHERE Name like '$name{'Name'}";
    # Okay got our query and now we would have data.
    tbl2obj ($table);
}

sub searchDB {
    my $self       = shift;
    my $tables     = shift;
    my $searchType = shift;
    my $params     = @_;
    my $key;
    my $query;
    my $queryHeader = "SELECT Name FROM ";
    my $queryBody   = "WHERE ";

    foreach $key (@{$tables}) {

        $query = $queryHeader . $key . " ";
        $query = $query . $queryBody;

        my $key;
        my $count = 0;

        foreach $key ( keys %{$params} ) {
            if ( $count == 0 ) {
                $query = $query . $key . " LIKE " . $params->{$key} . " ";
                $count++;
            }
            else {
                $query =
                  $query . $searchType . $key . " LIKE " . $params->{$key} . " ";
            }
        }
    }
}

sub runQuery {
    my $self  = shift;
    my $query = shift;
    my $dbh   = $self->{dbh};
    my $sth;

    # XXX How do I actually do this statment.
    $sth = $dbh->prepare($query);
    $sth->execute or die "SAA::DB: Can't Execute SQL Query: $DBI::errstr\n";

    return $sth;
}

