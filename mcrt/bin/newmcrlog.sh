#!/bin/sh
# $LWTBIN/newmcrlog.sh - rotate mcr_pusher and call_records.log files
# These log lines should be consolidated to one log file and 
# call_records.log should be dispensed with if it is only for 
# the flat file call record set up ( not database )
#-------------------------------------------------------
# Script Name: newmcrlog.sh 
# Version: 1.3 
# Last modified by: Jim Leonard, Apr. 22, 2002
# Requirements: call records. Run by root as cronjob at 59 23 * * *. 
# Description: rotate call_records.log files
# Created by: Kris Thompson
# Contact: coe-iae@cisco.com 
#-------------------------------------------------------

date=`date "+%m%d%y"`
LOGDIR=/var/mcrt
cd $LOGDIR

###   Do mcr_pusher_stdout.log   #####################
test -f mcr_pusher_stdout.log && mv mcr_pusher_stdout.log mcr_pusher_stdout-$date.log

touch mcr_pusher_stdout.log
chmod 644 mcr_pusher_stdout.log
chown swatcher mcr_pusher_stdout.log

###   Do mcr_pusher_stderr.log   #####################
test -f mcr_pusher_stderr.log && mv mcr_pusher_stderr.log mcr_pusher_stderr-$date.log

touch mcr_pusher_stderr.log
chmod 644 mcr_pusher_stderr.log
chown swatcher mcr_pusher_stderr.log

###   Do call_records.log        #####################
test -f call_records.log && mv call_records.log call_records-$date.log

touch call_records.log
chmod 644 call_records.log
chown swatcher call_records.log

###   Remove files more than 14 days old. ############
find . -name 'mcr_pusher_stdout-*.log' -mtime +14 -exec rm {} \;
find . -name 'mcr_pusher_stderr-*.log' -mtime +14 -exec rm {} \;
find . -name 'call_records-*.log' -mtime +14 -exec rm {} \;

logger -p cron.notice newmcrlog.sh completed `date`
# end of file $LWTBIN/newmcrlog.sh

