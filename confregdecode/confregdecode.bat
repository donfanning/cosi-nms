@echo off
REM
REM Copyright (c)2000 by cisco Systems, Inc. All rights reserved.
REM $Id$
REM

set CLASSPATH=cd.jar;%CLASSPATH%

jre.exe -cp %CLASSPATH% com.cisco.confregdecode.ConfregDecode
