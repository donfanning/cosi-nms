SNMP Search & Translate CGI

Copyright (C) 2001 Joe Clarke <marcus@marcuscom.com>
All rights reserved.

INTRODUCTION:
-------------

SNMP Search & Translate is a Web CGI front-end similar to the snmptranslate
command in the net-snmp SNMP stack.  

REQUIREMENTS:
-------------
This tool requires Perl 5, net-snmp and the associated SNMP.pm Perl modules, 
and a web server capable of serving out Perl CGI scripts.  net-snmp is
available for download from http://net-snmp.sourceforge.net.

If you wish to use the CHAP-like authentication security, the 
Digest::MD5 Perl module is also needed.  Digest::MD5 is available for 
download from any CPAN mirror (see http://www.cpan.org/SITES.html for a 
list of mirrors).

The CGI.pm module is also needed for the CGI side of things.  This is
a new requirement that enables easy use of cookies.  In the past, I
used my own CGI parsing routines.  CGI.pm is available for download from
any CPAN mirror (see http://www.cpan.org/SITES.html for a list of mirrors).

INSTALLATION and USE:
---------------------

SNMP Search & Translate is implemented as a CGI frontend with a persistent
MIB database backend.  These two components communicate with each other
via a TCP socket.  The reason for distributing things like this is
performance.  If the MIB database is stored in memory, searches and
translations take much less time to complete.  For small MIB trees, 
this implementation is somewhat of an overkill.

You will first need to install Perl 5 (5.004 or higher), and verify it is 
working.  Then, obtain the net-snmp libraries from 
http://sourceforge.net/projects/net-snmp.  You will need to install the
libraries as well as the SNMP.pm Perl module.

If you wish to use the module replacement feature (a parsing option that tells
net-snmp to replace older loaded MIB modules with newer one), you will
need to be running either the CVS version of net-snmp with patch #428884
applied to SNMP.pm, or apply the SNMP.patch (included with this distribution)
to net-snmp 4.2.1's SNMP.pm.

To apply the patch, run the command ``patch -p0 <SNMP.patch'' from the
perl/SNMP directory in the net-snmp source directory, then compile the
Perl module.  See the block in snmptransd.pl for turning this feature on
once you have the correct version of the Perl module loaded.

Copy the snmptransc.pl script to your web server's cgi-bin directory, and
edit the variables in the BEGIN { } clause to your environment.

Edit the variables in the BEGIN { } clause of the snmptransd.pl script
for your environment.

SNMP Search & Translate also provides for authenticating the client to the
server.  This is done by using a CHAP-like digest passing authentication
scheme.  A password is hashed on the client end and the server end.  The
client then sends the hash to the server who authenticates the session.
In this manner, the password is never passed in clear text on the network
unless the Web client is not using SSL.  This is configurable in the 
client HTML form as well as in the server's BEGIN { } clause.

Next, start the snmptransd.pl backend daemon.  On UNIX, it is best to use 
the command ``nohup snmptransd.pl &'' to run the daemon in the background
and to ignore the hangup signal.

Use the sample snmptrans.html page to test SNMP Search & Translate.  If
it works, you can modify the HTML as well as the CGI-returned HTML to
meet your needs.

If you get an error:

Undefined subroutine &SNMP::initMib called at ./snmptransd.pl line 71.

Chances are you have the wrong SNMP.pm module loaded.  The one needed for
snmptrans is available via the net-snmp package found at the URL above.

NOTES:
------

SNMP Search & Translate has been tested on Tru64 4.0F, FreeBSD 3.4, FreeBSD
4.3, and Solaris 2.6.  It should work on any version of UNIX that supports
net-snmp (namely AIX, HP/UX, Linux, *BSD, and IRIX).  No testing has been
done on Windows.  Assuming the SNMP.pm module can compile under Windows,
it should work.

This package is distributed under the BSD license.
