REM
REM Build batch script for the MISAL project.
REM $Id$

SET srcdir = .
SET docdir = %srcdir%\doc\api
SET package = com.marcuscom.MISAL
SET package_os = com\marcuscom\MISAL

SET RM = del
SET MKDIR = mkdir

SET JAVAC = C:\jdk1.3.1\bin\javac
SET JAVAC_FLAGS = -O
SET CLASSPATH = .;C:\classes\PerlTools.jar

SET JAVADOC = C:\jdk1.3.1\bin\javadoc
SET JAVADOC_FLAGS = -author -version -d %docdir%

SET JAR = C:\jdk1.3.1\bin\jar
SET JAR_FLAGS = -cf

REM classes:
%JAVAC% %JAVAC_FLAGS% -classpath %CLASSPATH% %srcdir%\%package_os%\*.java

REM jar:
%JAR% %JAR_FLAGS% %srcdir%\MISAL.jar %srcdir%\%packages_os%\*.class

REM docs:
%MKDIR% %docdir%
%JAVADOC% %JAVADOC_FLAGS% -classpath %CLASSPATH% %package%

REM test:
%JAVAC% %JAVAC_FLAGS% -classpath %CLASSPATH% %srcdir%\MISALTest.java

