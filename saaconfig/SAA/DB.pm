package SAA::DB;

# oansari 2.11.2002: adding required methods: add_source
# oansari 2.12.2002: added add_user, modified add_source to take object handle
#					 instead of vars, and populated $self->error and returning,
#					 instead of croaking.

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
        my ($that, @args) = @_;
        my $class = ref($that) || $that;

        my $self = {
                dbh   => undef,
                error => undef,
        };

        $self->{dbh} = DBI->connect('dbi:' . $DB_DRIVER . ':' . $DB_NAME,
                $DB_USER, $DB_PASS)
            or croak "SAA::DB: Unable to connect to database " . $DB_NAME;

        bless($self, $class);
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
        #Takes in the handle for the source object, and pulls data out from it.

        use vars qw ($src @ary @IDs @Vals $sth @protocols @types);

        #note: see conf::tables.pm for hints on schema. do note: if some of the vars
        #above are not specified by user during configuration, the calling party needs
        #to still pass _undef_ instead of that var

        #also note that SrcSupportedProtocols is an array not a scalar.
        my $self = shift;
        my $src  = shift;
        my $dbhx = $self->{dbh};

        my %SrcValHash = (
                SrcId       => undef,
                SrcAlias    => $src->name(),
                SrcIpAddr   => $src->addr(),
                SrcStatus   => $src->status(),
                SrcDescr    => undef,           #method not present in Source.pm
                SrcHostname => undef,           # ""
                SrcReadComm       => $src->read_community(),
                SrcWriteComm      => $src->write_community(),
                SrcSnmpVersion    => $src->snmp_version(),
                SrcIosVersion     => $src->ios_version(),
                SrcRttAppVersion  => $src->saa_version(),
                SrcSupportedTypes => $src->type_supported(),    #a ref to a hash
                SrcSupportedProtocols =>
                    $src->protocol_supported()                  #a ref to a hash
        );

        #some rudimentary checks to ensure we populate the "NOT NULL" fields in the tables.
        if (!($SrcValHash{SrcAlias})) {
                $self->error("SrcAlias needs to be defined");
                return;
        }
        if (!($SrcValHash{SrcIpAddr})) {
                $self->error("SrcIpAddr needs to be defined");
                return;
        }

        #check to see if src already exists and if it does, then balk out.
        my $selector =
            "select \* from SAA_SOURCES where SrcIpAddr=\"$SrcValHash{SrcIpAddr}\" or SrcAlias=\"$SrcValHash{SrcAlias}\"";
        if (scalar(@ary = $dbhx->selectrow_array($selector)) != 0) {
                $self->error(
                        "DB.pm : SrcIpAddr and.or SrcAlias of this source is already present: $SrcValHash{SrcIpAddr} and.or $SrcValHash{SrcAlias}"
                );
                return;
        }

        undef @ary;

        #everything looks good, so let's insert this source into database:

        #first, lets churn up the next available SrcId
        my $srcidchecker = "select \* from  SAA_SOURCES order by SrcId DESC";
        if (scalar(@ary = $dbhx->selectrow_array($srcidchecker)) == 0) {
                $SrcValHash{SrcId} = "1";
        } else {
                $SrcValHash{SrcId} = ++$ary[0];
        }

        my $key;
        foreach $key (keys %SrcValHash) {

                #put a special catch for the hash refs for supported types
                if ($key eq "SrcSupportedTypes") {
                        foreach (keys %{($SrcValHash{SrcSupportedTypes})}) {
                                push (@types, $_);
                        }
                        push (@Vals, "\"@types\"");
                        push (@IDs,  $key);
                        next;
                }

                #also for hash ref for protocols:
                if ($key eq "SrcSupportedProtocols") {
                        foreach (keys %{($SrcValHash{SrcSupportedProtocols})}) {
                                push (@protocols, $_);
                        }
                        push (@Vals, "\"@protocols\"");
                        push (@IDs,  $key);
                        next;
                }

                #as for the rest, treat them as regular values..
                if ($SrcValHash{$key}) {

                        #this is to get rid of all the vars not defined by user,
                        #so we dont bother inserting them into the table
                        push (@IDs,  $key);
                        push (@Vals, "\"$SrcValHash{$key}\"");

                }
        }

        my $IDs  = join (',', @IDs);
        my $Vals = join (',', @Vals);
        my $inserter = "insert into SAA_SOURCES \($IDs\) VALUES \($Vals\)";

        if (!($sth = $dbhx->prepare($inserter))) {
                $self->error("Failed to prepare query: " . $dbhx->errstr());
                return;
        }

        if (!($sth->execute())) {
                $self->error("Failed to execute query: " . $dbhx->errstr());
                return;
        }

        1;
}

sub add_target {

        #adds target to SAA_TARGETS table in saaconf database
        #alls you have to do is pass it the target handle
        my $self   = shift;
        my $target = shift;
        my $dbhx   = $self->{dbh};
        use vars qw ($key @ary @IDs @Vals $sth);

        my %TargetHash = (
                TgtId     => undef,
                TgtAlias  => $target->name(),
                TgtIpAddr => $target->addr(),
                TgtStatus => $target->status(),
                TgtDescr  => undef,             #not defined in Target.pm as yet
                TgtHostName      => undef,      # ""
                TgtReadComm      => undef,      # ""
                TgtWriteComm     => undef,      # ""
                TgtIosVersion    => undef,      #""
                TgtRttAppVersion => undef       #""
        );

        #first, lets churn up the next available TargetId
        my $tgtidchecker = "select \* from  SAA_TARGETS order by TgtId DESC";
        if (scalar(@ary = $dbhx->selectrow_array($tgtidchecker)) == 0) {
                $TargetHash{TgtId} = "1";
        } else {
                $TargetHash{TgtId} = ++$ary[0];
        }

        #now to pull IDs and values from the %TargetHash for the eventual query
        foreach $key (keys %TargetHash) {

                if ($TargetHash{$key}) {

                        #this is to get rid of all the vars not defined by user,
                        #so we dont bother inserting them into the table
                        push (@IDs,  $key);
                        push (@Vals, "\"$TargetHash{$key}\"");
                }
        }
        my $IDs  = join (',', @IDs);
        my $Vals = join (',', @Vals);
        my $inserter = "insert into SAA_TARGETS \($IDs\) VALUES \($Vals\)";

        if (!($sth = $dbhx->prepare($inserter))) {
                $self->error("Failed to prepare query: " . $dbhx->errstr());
                return;
        }

        if (!($sth->execute())) {
                $self->error("Failed to execute query: " . $dbhx->errstr());
                return;
        }
}

sub add_user {

        #this as the name suggests, lets callers add NEW users to the SAA_USERS table.
        #to modify userfields use &modify_user
        #simply pass it the handle for the user object and it will pull requsite data itself

        my $self = shift;
        my $user = shift;
        my $dbhx = $self->{dbh};

        use vars qw ($key @IDs @Vals @ary);

        my %UserHash = (
                UserId      => undef,
                UserName    => $user->username(),
                FirstName   => $user->firstname(),
                LastName    => $user->lastname(),
                Password    => $user->password(),
                Permissions => $user->perms()
        );

        #first, lets churn up the next available UserId
        my $useridchecker = "select \* from  SAA_USERS order by UserId DESC";
        if (scalar(@ary = $dbhx->selectrow_array($useridchecker)) == 0) {
                $UserHash{UserId} = "1";
        } else {
                $UserHash{UserId} = ++$ary[0];
        }

        #now to pull IDs and values from the %UserHash for the eventual query
        foreach $key (keys %UserHash) {

                if ($UserHash{$key}) {

                        #this is to get rid of all the vars not defined by user,
                        #so we dont bother inserting them into the table
                        push (@IDs,  $key);
                        push (@Vals, "\"$UserHash{$key}\"");
                }
        }
        my $IDs  = join (',', @IDs);
        my $Vals = join (',', @Vals);
        my $inserter = "insert into SAA_USERS \($IDs\) VALUES \($Vals\)";

        if (!($sth = $dbhx->prepare($inserter))) {
                $self->error("Failed to prepare query: " . $dbhx->errstr());
                return;
        }

        if (!($sth->execute())) {
                $self->error("Failed to execute query: " . $dbhx->errstr());
                return;
        }

        1;
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

        if (scalar(@_) < 1) {
                croak "DB::get_object: Must specify at least one argument";
        }

        my $obj = shift;
        if (!$objectToGetMethod{$obj}) {
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
        croak "Attempt to call private method" if ($class ne __PACKAGE__);
        my ($query, $dbh, $sth, $src, $srcs);

        $query = "SELECT * FROM $TBL_SOURCE";
        $dbh   = $self->dbh();

        if (@_) {

                # Arguments have been passed.  Use the arguments to build SQL queries.
                $query .= " WHERE ";
                my $arg;
                my %args = @_;
                foreach $arg (keys %args) {

                        # Handle LIKE '%string%' queries.
                        if ($args{$arg} =~ /[^\\]%/) {
                                $query .= "$arg LIKE '$args{$arg}',";
                        } else {
                                $query .= "$arg='$args{$arg}',";
                        }
                }
                $query =~ s/,$//;
        }

        if (!($sth = $dbh->prepare($query))) {
                $self->error("Failed to prepare query: " . $dbh->errstr());
                return;
        }

        if (!($sth->execute())) {
                $self->error("Failed to execute query: " . $dbh->errstr());
                return;
        }

        #finally get data back using fetchrow_hashref()
        # question1 : why are we creating a source again with this data that was ingested in the DB?
        # the data was ingested by creating a source in the first place...

        my $row;
        while ($row = $sth->fetchrow_hashref()) {

                $src =
                    new SAA::Source($row->{Name}, $row->{Address},
                        $row->{SNMP_Version});
                $src->read_community($row->{Read_Community});
                $src->write_community($row->{Write_Community});
                $src->_saa_version($row->{SAA_Version});
                $src->_ios_version($row->{IOS_Version});
                $src->_status($row->{Status});
                my ($type, $protocol);

                foreach $type (split (/;/, $row->{Supported_Types})) {
                        $src->_add_type_supported($type);
                }
                foreach $protocol (split (/;/, $row->{Supported_Protocols})) {
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
        croak "Attempt to call private method" if ($class ne __PACKAGE__);
        my ($query, $dbh, $sth, $target, $targets);

        $query = "SELECT * FROM $TBL_TARGET";
        $dbh   = $self->dbh();

        if (@_) {

                # Arguments have been passed.  Use the arguments to build SQL queries.
                $query .= " WHERE ";
                my $arg;
                my %args = @_;
                foreach $arg (keys %args) {

                        # Handle LIKE '%string%' queries.
                        if ($args{$arg} =~ /[^\\]%/) {
                                $query .= "$arg LIKE '$args{$arg}',";
                        } else {
                                $query .= "$arg='$args{$arg}',";
                        }
                }
                $query =~ s/,$//;
        }

        if (!($sth = $dbh->prepare($query))) {
                $self->error("Failed to prepare query: " . $dbh->errstr());
                return;
        }

        if (!($sth->execute())) {
                $self->error("Failed to execute query: " . $dbh->errstr());
                return;
        }

        my $row;
        while ($row = $sth->fetchrow_hashref()) {

                $target = new SAA::Target($row->{Name}, $row->{Address});
                $target->_status($row->{Status});
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
