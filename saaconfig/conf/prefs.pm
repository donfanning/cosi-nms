package conf::prefs;

use strict;
use vars qw(@ISA @EXPORT_OK);
use Exporter;

@ISA = qw(Exporter);
## DO NOT REMOVE NEXT LINE ##
@EXPORT_OK = qw(
  $DB_HOST
  $DB_NAME
  $DB_USER
  $DB_PASS
  KEY
);

## DO NOT REMOVE NEXT LINE ##
use vars qw(
  $DB_HOST
  $DB_NAME
  $DB_USER
  $DB_PASS
);

## DO NOT REMOVE NEXT LINE ##
## BEGIN PREFERENCES
$DB_HOST = 'localhost';
$DB_NAME = 'saaconf';
$DB_USER = 'saa';
$DB_PASS = 's44';
# Random key used in Blowfish ciphering.
# XXX This key should not be statically defined here.  In the release, this
# should be configurable by the end user so that all keys will be different.
use constant KEY => pack( "H16", 'aIC9e8!Cmtdyu4GV' );


## END PREFERENCES

1;
