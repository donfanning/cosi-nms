#!/bin/sh

rcsid='$Id$'

echo '***************************************************************'

echo This script can only be used with RME 3.1 and higher.
echo
echo If you do not want to install this patch, press CTRL+C.
echo
echo If you want to install this patch, press Enter or Return
echo to continue.

echo '****************************************************************'
read reply

exec ./.install.pl
