SNMP Search & Translate CGI

Copyright (C) 2001 Joe Clarke <marcus@marcuscom.com>
All rights reserved.

INTRODUCTION:
-------------

SNMP Search & Translate is a Web CGI front-end to the snmptranslate
functionality in the net-snmp SNMP stack.  

REQUIREMENTS:
-------------
This tool requires Perl 5, net-snmp and the associated SNMP.pm Perl modules, 
and a web server capable of serving out Perl CGI scripts.

INSTALLATION and USE:
---------------------

You will first need to install Perl 5 (5.004 or higher), and verify it is 
working.  Then, obtain the net-snmp libraries from 
http://sourceforge.net/projects/net-snmp.  You ill need to install the
libraries as well as the SNMP.pm Perl module.

Copy the snmptransc.pl script to your web server's cgi-bin directory, and
edit the variables in the BEGIN { } clause to your environment.

Edit the variables in the BEGIN { } clause of the snmptransd.pl script
for your environment.

Next, start the snmptransd.pl backend daemon.  On UNIX, it is best to use 
the command ``nohup snmptransd.pl &'' to run the daemon in the background
and to ignore the hangup signal.

Use the sample snmptrans.html page to test SNMP Search & Translate.  If
it works, you can modify the HTML as well as the CGI-returned HTML to
meet your needs.

NOTES:
------

SNMP Search & Translate has been tested on Tru64 4.0F, FreeBSD 3.4, FreeBSD
4.3, and Solaris 2.6.  It should work on any version of UNIX that supports
net-snmp (namely AIX, HP/UX, Linux, *BSD, and IRIX).  No testing has been
done on Windows.  Assuming the SNMP.pm module can compile under Windows,
it should work.

This package is distributed under the BSD license.
