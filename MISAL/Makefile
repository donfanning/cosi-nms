#
# Makefile for the MISAL project. 
# $Id$

srcdir=	.
docdir=	$(srcdir)/doc/api
package=	com.marcuscom.MISAL
package_os=	com/marcuscom/MISAL

RM=	/bin/rm

JAVAC=	/usr/local/jdk1.1.8/bin/javac
JAVAC_FLAGS=	-O

JAVADOC=	/usr/local/jdk1.1.8/bin/javadoc
JAVADOC_FLAGS=	-author -version -d $(docdir)

JAR=	/usr/local/jdk1.1.8/bin/jar
JAR_FLAGS=	-cf

all: jar docs

jar: classes
	$(JAR) $(JAR_FLAGS) $(srcdir)/MISAL.jar $(srcdir)/$(package_os)/*.class

classes:
	$(JAVAC) $(JAVAC_FLAGS) $(srcdir)/$(package_os)/*.java

docs:
	$(JAVADOC) $(JAVADOC_FLAGS) $(package)

clean:
	$(RM) -f $(srcdir)/MISAL.jar
	$(RM) -f $(srcdir)/$(package_os)/*.class
	$(RM) -rf $(docdir)/*.html
