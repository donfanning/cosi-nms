package conf::prefs;

use strict;
require 5.002;

## DO NOT REMOVE NEXT LINE ##
use vars qw(
$DB_HOST
$DB_NAME
$DB_USER
$DB_PASS
);

use Exporter;

my @ISA = qw(Exporter);
## DO NOT REMOVE NEXT LINE ##
my @EXPORT_OK = qw(
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

## END PREFERENCES
