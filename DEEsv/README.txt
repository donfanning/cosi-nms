Project DEEsv for Resource Manager Essentials 3.4 and Higher

Author: Joe Clarke <marcus@marcuscom.com>

$Id$

INTRODUCTION:
-------------

This tool is designed for CiscoWorks users running RME 3.4 or higher
and have the Data Extracting Engine (DEEv2) product installed.  This tool
takes the XML data output by the cwexport interface to DEE, and converts
it to xSV (e.g. CSV) in a similar format to the RME Detailed Device Report.

REQUIREMENTS:
-------------

* CiscoWorks Resource Manager Essentials 3.4 or higher on Windows 2000,
  Solaris 7, or Solaris 8.
* Data Extracting Engine (DEEv2) (DEE can be obtained from 
  http://www.cisco.com/cgi-bin/tablebuild.pl/cw2000-rme).
* ALL of the prerequisites for RME and DEE are met.

INSTALLATION:
-------------

Installation under Windows 2000:
--------------------------------

* Unzip deesv-win-v10.zip

* Change directory to deesv-win-v10

* Run install.cmd


Installation under Solaris 7 or 8:
----------------------------------

* Run 'uncompress -c deesv-unix-v10.tar.Z | tar -xvf -'

* Change directory to deesv-unix-v10

* Run ./install.sh


USING DEEsv:
------------

DEEsv installs a DEEsv.pl script in NMSROOT/bin.  DEEsv accepts all the same
arguments as the cwexport command.  For information on the cwexport command
line syntax, see the on-line documentation within RME for DEE, or, on
Solaris, look at the cwexport(1) manpage in NMSROOT/man/man1/cwexport.1.
The one cwexport command DEEsv does _not_ support is the ``config'' command.
DEEsv only operates on inventory data.  DEEsv also accepts one additional
argument: -sep <character>.  This allows one to specify an alternate 
separator character specified by <character>.  The default is a comma (',').

The output produced by DEEsv will be written to the file specified by the
-f argument.  If the -f is omitted, then the data will be written to
standard output (i.e. the console).  The data is similar to the format
produced by the RME Detailed Device Report.

NOTE: The file specified by the -f option must be writable by casuser.


EXAMPLE:
--------

To extract the inventory data for a device, 14.32.6.12, run the command:

DEEsv.pl inventory -u admin -p admin -device 14.32.6.12 -f /tmp/14.32.6.12.csv

To do the same thing, but using the recommended, secure mode:

DEEsv.pl -device 14.32.6.12 -f /tmp/14.32.6.12.csv

NOTE: For this to work, the CWEXPORTFILE environment variable must be
set to the path of the file that specifies the CiscoWorks username and
password.

To extract inventory data for all the devices in the database, run the
command:

DEEsv.pl inventory -u admin -p admin -f /tmp/all_devices.csv


BUGS:
-----

* DEEsv cannot be run remotely.  This will be addressed in an upcoming
  release.


ADDITIONAL NOTES:
-----------------

While most of this Open Source released under the BSD license, it still
relies on components from CiscoWorks which is copyright of Cisco
Systems, Inc.

CiscoWorks, Resource Manager Essentials, and Data Extracting Engine are
registered trademarks of Cisco Systems, Inc.
All rights reserved.
