cisco Systems IOS(tm) Config-Register Decoder Readme
----------------------------------------------------

$Id$

Requirements:
-------------

* Java Runtime Environment (JRE) 1.1.5 or higher
* Windows or UNIX operating system (FreeBSD recommended)
* 32 MB or RAM
* Color monitor with display set to 256 or more colors

Installation (From Precompiled Package):
----------------------------------------

* Unpack the confregdecode-1.0.tar.gz or confregdecode-1.0.zip file 
(both contain identical contents)
* Change directory to the confregdecode-1.0 directory.
* On UNIX, you must edit confregdecode.sh, and change the JRE variable to
point to the location where jre is installed your system.  On Windows, this
should be in your path.
* On Windows, run confregdecode, on UNIX, run ./confregdecode.sh

Installation (From Java Source):
--------------------------------

* Unpack the confregdecode-src-1.0.tar.gz or confregdecode-src-1.0.zip file 
(both contain identical contents)
* Change directory to the confregdecode-src-1.0 directory.
* On UNIX, edit the Makefile so that all the paths are correct, and type
``make jar''.  You will need javac (the Java compiler) 1.1.5 or later.
On Windows, you may be able to use the Makefile, else, type
``javac com/marcuscom/confregdecode/ConfregDecode.java''
* On Windows, run confregdecode, on UNIX, run ./confregdecode.sh

Running in Applet Mode:
-----------------------

A ConfregDecode.html file is distributed along with the Configuration
Register Decoder Package.  This HTML file can be used as a template to
invoke the applet version of the tool.  The Configuration Register Decoder
jarfile has both the code necessary to be an applet or application.  No
extra compilation is required.

Notes:
------

* More on the Cisco IOS(tm) configuration register can be found at
http://www.cisco.com/univercd/cc/td/doc/product/iaabu/distrdir/dd4700m/vconfig.htm
* This program contains code written by David Flanagan.  All code is
distributed under the BSD license except where noted in the header.

IOS is a registered trademark of Cisco Systems, Inc.
All rights reserved.
