#
# Makefile for the MISAL project.
# $Id$

SRCDIR=		.
DOCDIR=		${SRCDIR}/doc/api
JARDIR=		/usr/local/share/java/classes
CLASSPATH=	.:${JARDIR}/jakarta-oro.jar

JAVADOC=	/usr/local/jdk1.3.1/bin/javadoc
JAVADOC_FLAGS=	-author -version -d $(DOCDIR)
JAVAC=		/usr/local/jdk1.3.1/bin/javac
JAVAC_FLAGS=	-O
JAR=		/usr/local/jdk1.3.1/bin/jar
JAR_FLAGS=	-cf

PACKAGE=	com.marcuscom.MISAL
PACKAGE_OS=	com/marcuscom/MISAL

RM=	/bin/rm
MKDIR=	/bin/mkdir -p

all: jar docs

jar: classes
	${JAR} ${JAR_FLAGS} ${SRCDIR}/MISAL.jar ${SRCDIR}/${PACKAGE_OS}/*.class

classes:
	${JAVAC} ${JAVAC_FLAGS} -classpath \
		${CLASSPATH} ${SRCDIR}/${PACKAGE_OS}/*.java

test:
	${JAVAC} ${JAVAC_FLAGS} -classpath ${CLASSPATH} \
		${SRCDIR}/MISALTest.java ${SRCDIR}/MISALTestIOS.java

docs:
	${MKDIR} ${DOCDIR}
	${JAVADOC} ${JAVADOC_FLAGS} -classpath ${CLASSPATH} ${PACKAGE}

clean:
	${RM} -f ${SRCDIR}/MISAL.jar
	${RM} -f ${SRCDIR}/${PACKAGE_OS}/*.class
	${RM} -f ${DOCDIR}/*.* ${DOCDIR}/package-list
	${RM} -rf ${DOCDIR}/com
	${RM} -f ${SRCDIR}/MISALTest.class ${SRCDIR}/MISALTestIOS.class
