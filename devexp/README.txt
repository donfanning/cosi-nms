Project DevExp for Resource Manager Essentials 3.1 and Higher

Author: Joe Clarke <jclarke@cisco.com>

$Id$

INTRODUCTION:
-------------

This tool is designed for customers running RME 3.1 or higher.  It automates
the device export functionality in RME.  This tool can be run from cron or at
to produce regular CSV of XML "dumps" of the RME inventory.

REQUIREMENTS:
-------------

* Resource Manager Essentials 3.1 or higher on Windows NT, Windows 2000,
  Solaris 2.6, Solaris 7, HP/UX 11.0, or AIX 4.3.3.
* ALL of the prerequisites for RME are met.

INSTALLATION:
-------------

Installation under Windows NT or 2000:
--------------------------------------

* Unzip devexp-win-v10.zip

* Change directory to devexp-win-v10

* Run install.cmd


Installation under UNIX:
------------------------

* Run 'uncompress -c devexp-unix-v10.tar.Z | tar -xvf -'

* Change directory to devexp-unix-v10

* Run ./install.sh


USING DevExp:
-------------

DevExp installs most things in {CW2000}/objects/devexp, with the actual
script in {CW2000}/bin.  First, edit the configuration file in
{CW2000}/objects/devexp/devexp.conf.  The options are all commented.  The
defaults are usually acceptable for most options, but you will want to
specify an output file.

Once the configuration file is to your liking, run 
{CW2000}/bin/devexp.pl (on Windows, you will need to run:
perl.exe {CW2000}\bin\devexp.pl).  Then, check the file you specified in
the OUTPUT_FILE variable in the configuration file.  Do things look
somewhat correct?  If not, double-check your config file, and, if things
still don't work right, please email me.

Once you'ver verified it can run on-demand, you can set it up to run
in cron (on UNIX) or at (on Windows).  Below are some examples to do this.
Please refer to the cron and at documentation for more specific information.

UNIX crontab entry (run once nightly at 1:00 am):
0	1	*	*	*	/opt/CSCOpx/bin/devexp.pl 2>&1 | /usr/lib/sendmail root

Windows at command (run once nightly at 1:00 am):
at 01:00 /every:M,T,W,Th,F,S,Su perl.exe {CW2000}\bin\devexp.pl

Resource Manager Essentials is a registered trademark of Cisco Systems, Inc.
All rights reserved.
