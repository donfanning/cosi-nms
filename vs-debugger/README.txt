 
                        README file for dubugger
 
                           October 8, 2001 
                      
                             debugger v1.0
 
                          Copyright (C) 2001 


This script is made available and released under the Mozilla Public License.


debugger :
===============

	This is a GUI Tool written using TCL/TK(8.0) which can be used to
analyse voice debugs on cisco routers . Currently the tool supports 3 voice
debugs which are supported on Cisco's IOS namely ( 1. debug isdn q931 2. debug
voip ccapi inout 3. debug vtsp all ) . The tool can be invoked by giving the
tool name on Unix command promptx command which we need to cut and paste
the router debug messages and choose the appropriate debug button . 

	Usage : debugger &

	 Then it highlights the key events of that debug in the messages and
invokes a new window  to give the key parameters that have been collected (
like the calling / called number , Codec negotiated , Fax capability , 
encapsulation , matching dial-peer etc ) and also a detailed report on the
call flow what each function means ( in IOS context ) and also translates the
hexadecimal codes obtained in the debugs to understandable macro format which
is human readable . The tool could be enhanced to support other debugs as well
by adding Tcl plugin procedures .

Uses :
======
	The tool has been found to be useful to cisco's TAC engineers and
it would be also helpful to cisco's customers who need to debug voice related
features . It saves a lot of time by translating various capabilities
negotiated during call setup (which are in hex format ) into human readable 
Macros , so that the engineer analysing the debug need not visit the CCO web-
pages everytime to translate these codes. 
 
Environment setup :
===================

1. The tool requires wish8.0 software to be installed.

2. we need to set the DISPLAY variable to the machine's IP address:0.0

	Please note the :0.0 at the end of the IP address .
e.g.	for csh use "setenv DISPLAY 192.135.243.245:0.0"
e.g.	for ksh use "export DISPLAY=192.135.243.245:0.0"

3. If you are invoking the tool on the server from a local sun workstation and
if you get the error message "could not connect to server , only authorised
clients can connect" then invoke a terminal on your sunworkstation and type
"xhost +" on the command prompt . This is to allow an application running on
the server to be displayed on your local machine.

