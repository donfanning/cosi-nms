package SAA::DB;

use strict;
require 5.002;
use DBI;
use SAA::Globals;
use SAA::SAA_MIB;
use Carp;

sub new {

    my ( $that, @args ) = @_;
    my $class  = ref($that) || $that;
    my %params = @args;
    my $self   = {};
    $self = {
        Driver   => $params{Driver},
        Database => $params{Database},
        Hostname => $params{Hostname},
        User     => $params{User},
        Password => $params{Password}

        #		dbh			=> undef
    };

    # Create connect to database.
    #	my $dbh = DBI->connect (
    #			"DBI:$self{'Driver'}:$self{'Datbase'}:$self{'Hostname'}",
    #			$self{'User'},
    #			$self{'Password'}
    #			);

    bless( $self, $class );

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

# XXX This object will create a INSERT Statment and apply it 
# to the database.  At this point it simply prints the query.

sub setSAAObject {
    my $self  = shift;
    my $table = shift;
    my $obj   = shift;
    
	if ($table != "Sources" || $table != "Targets" || $table != "Operations") {
	
		croak "SAA::DB: Table $table is not a valid table.";
	}

	if (!$obj) {

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
"INSERT INTO $table (sourceName,targetName,operationName,Description,startTime,NVRam,RowAge,Owner,Status,Life) values ('";

    }


}

sub getSAAObject {
    my $self = shift;

    if ( !@_ ) {

        croak
"SAA::DB: No defaults for sub please specify\n\tgetSAAObject(Tablename, name => value)\n";
    }

    my $table = shift;
    my %name  = @_;
    my $key;
    my $query = "SELECT * FROM $table WHERE ";
    foreach $key ( keys %name ) {
        print "Key: $key Value: $name{$key}\n";
    }
    print "--Database stuff--\n";
    print "Database: " . $self->database() . " \n";
}

