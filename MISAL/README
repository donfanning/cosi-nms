MarcusCom Intelligent Socket Abstraction Library (MISAL)
--------------------------------------------------------

$Id$

MISAL is a multi-threaded Java library that allows for manipulation of TCP
sockets.  MISAL is designed to wrap around sockets and give an easy interface
to sending an receiving data on a socket.

MISAL itself is fairly generic, and can be used for almost any type of TCP 
socket.  It is mostly used for things like telnet.  MISAL knows about telnet
options, and will reply with DONT or WONT for all options.

MISAL can be extended to support all kinds of specific socket types as well
as specific network node types.  The default MISAL distribution comes with
a Cisco IOS subclass.

Right now, MISAL is considered to be beta-quality code.


BUILDING:
---------

MISAL requires JDK 1.1 or higher, and will work on UNIX, MacOS X, or 
Windows (MacOS 9 has not been tested).

MISAL requires PerlTools from
http://www.savarese.org/oro/downloads/index.html#PerlTools.  PerlToos.jar
must be in your classpath before building or running MISAL-based applications.

To build MISAL on UNIX or MacOS X, use the included Makefile.  You may need
to edit this Makefile to point to the correct locations for javac, jar,
javadoc, and other system binaries.  Once the Makefile is correct for your
environment, type:

> make all
> make test

This will build MISAL.jar, all the JavaDoc API documentation, and the
MISALTest.class.

To build MISAL on Windows (95/98/Me, NT, 2000, and maybe even XP), use 
build.bat:

> build

This will build MISAL.jar, all the JavaDoc API documentation, and the
MISALTest.class.


USING:
------

See the included JavaDoc documentation and MISALTest.java for usage guidlines.


MISAL is distributed under the BSD license.
