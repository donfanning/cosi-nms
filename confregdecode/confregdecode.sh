#!/bin/sh

#
# Copyright (c)2000-2001 by MarcusCom, Inc.  All rights reserved.
# $Id$
#

# Change this to your path to jre
JRE=/usr/local/jdk1.1.8/bin/jre
# End changeable things

CLASSPATH=cd.jar:${CLASSPATH}

exec ${JRE} -cp ${CLASSPATH} com.cisco.confregdecode.ConfregDecode
