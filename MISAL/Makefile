#
# Makefile for the MISAL project. 
# $Id$

srcdir=	.
docdir=	$(srcdir)/doc/api
package=	com.marcuscom.MISAL
package_os=	com/marcuscom/MISAL

RM=	/bin/rm
MKDIR= /bin/mkdir

JAVAC=	/usr/local/jdk1.3.1/bin/javac
JAVAC_FLAGS=	-O
CLASSPATH=.:/usr/local/share/java/classes/PerlTools.jar

JAVADOC=	/usr/local/jdk1.3.1/bin/javadoc
JAVADOC_FLAGS=	-author -version -d $(docdir)

JAR=	/usr/local/jdk1.3.1/bin/jar
JAR_FLAGS=	-cf

all: jar docs

jar: classes
	$(JAR) $(JAR_FLAGS) $(srcdir)/MISAL.jar $(srcdir)/$(package_os)/*.class

classes:
	$(JAVAC) $(JAVAC_FLAGS) -classpath $(CLASSPATH) $(srcdir)/$(package_os)/*.java

test:
	$(JAVAC) $(JAVAC_FLAGS) -classpath $(CLASSPATH) $(srcdir)/MISALTest.java

docs:
	$(MKDIR) -p $(docdir)
	$(JAVADOC) $(JAVADOC_FLAGS) -classpath $(CLASSPATH) $(package)

clean:
	$(RM) -f $(srcdir)/MISAL.jar
	$(RM) -f $(srcdir)/$(package_os)/*.class
	$(RM) -rf $(docdir)
	$(RM) -f $(srcdir)/MISALTest.class
