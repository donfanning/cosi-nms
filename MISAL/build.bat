REM
REM Build batch script for the MISAL project.
REM $Id$

SET SRCDIR=.
SET DOCDIR=%SRCDIR%\doc\api
SET JARDIR=C:\java\classes
SET CLASSPATH=.;%JARDIR%\jakarta-oro.jar

SET JAVAC=C:\jdk1.3.1\bin\javac
SET JAVADOC=C:\jdk1.3.1\bin\javadoc
SET JAVADOC_FLAGS=-author -version -d %DOCDIR%
SET JAVAC_FLAGS=-O
SET JAR=C:\jdk1.3.1\bin\jar
SET JAR_FLAGS=-cf

SET PACKAGE=com.marcuscom.MISAL
SET PACKAGE_OS=com\marcuscom\MISAL

SET RM=del
SET MKDIR=mkdir


if "%1"=="clean" goto clean

REM classes:
%JAVAC% %JAVAC_FLAGS% -classpath %CLASSPATH% %SRCDIR%\%PACKAGE_OS%\*.java

REM jar:
%JAR% %JAR_FLAGS% %SRCDIR%\MISAL.jar %SRCDIR%\%PACKAGE_OS%\*.class

REM docs:
%MKDIR% %DOCDIR%
%JAVADOC% %JAVADOC_FLAGS% -classpath %CLASSPATH% %PACKAGE%

REM test:
%JAVAC% %JAVAC_FLAGS% -classpath %CLASSPATH% %SRCDIR%\MISALTest.java MISALTestIOS.java

goto end

:clean
%RM% /q/f %SRCDIR%\MISAL.jar
%RM% /q/f %SRCDIR%\%PACKAGE_OS%\*.class
%RM% /q/f %DOCDIR%\*.* %DOCDIR%\package-list
%RM% /q/f/s %DOCDIR%\com
%RM% /q/f %SRCDIR%\MISALTest.class %SRCDIR%\MISALTestIOS.class

:end
