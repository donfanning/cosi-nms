#!/bin/sh
# $Id$

DIR=/oss/utils/ciscoconf
PID=/var/run/ciscoconfd.pid
LOGFILE=/var/log/cisco
INTERVAL=600

$DIR/ciscoconfd -s local3 -p $PID -u root -g root -t $INTERVAL -r $DIR/ciscoconfr $LOGFILE
