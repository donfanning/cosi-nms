#
# Makefile for confregdecode
# $Id$
#

JAVAC=	/usr/local/jdk1.1.8/bin/javac
JAVAC_FLAGS=	-O -g
JAR=	/usr/local/jdk1.1.8/bin/jar
RM=	/bin/rm

all:
	$(JAVAC) $(JAVAC_FLAGS) com/marcuscom/confregdecode/ConfregDecode.java

jar: all
	$(JAR) -cvf cd.jar com/marcuscom/confregdecode/*.class

clean:
	$(RM) -f com/marcuscom/confregdecode/*.class
	$(RM) -f cd.jar
