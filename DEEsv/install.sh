#!/bin/sh

rcsid='$Id$'

echo '***************************************************************'

echo "This will install DEEsv for Resource Manager Essentials 3.4."
echo "This adds the capability to convert XML produced by DEEv2 to"
echo "xSV format (for example, CSV)."
echo
echo "If you do not want to install this package, press CTRL+C."
echo
echo "If you want to install this patch, press Enter or Return"
echo "to continue."

echo '****************************************************************'
read reply

exec ./.install.pl
