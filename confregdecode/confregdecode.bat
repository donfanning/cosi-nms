@echo off
REM
REM Copyright (c)2000 by MarcusCom, Inc. All rights reserved.
REM $Id$
REM

set CLASSPATH=cd.jar;%CLASSPATH%

jre.exe -cp %CLASSPATH% com.marcuscom.confregdecode.ConfregDecode
