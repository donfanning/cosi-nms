@echo off

set rcsid = $Id$

echo ***************************************************************

echo This script can ONLY be used with RME 3.1 and higher.
echo.
echo If you do not want to install this patch, press CTRL+C and
echo then press Y to exit.
echo.
echo If you want to install this patch, press Enter to continue
echo.
pause
"perl.exe" _install.pl
goto exit

:exit
echo.
echo ****************************************************************

