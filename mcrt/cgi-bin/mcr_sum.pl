#!/usr/local/bin/perl -w
#-------------------------------------------------------
# Script Name: mcr_sum.pl
# Version: 1.4.1 
# Last modified by: Jim Leonard August 31, 2000
# Requirements: 
# Description: 	script pulls out variables of interest from the input data (modem 
# 		call records) and organized them (the variabled) into a comma separated format. 
# Created by: M. Saifur Rahman & Jim Leonard
# Date: March 10, 1999
# Contact: coe-iae@cisco.com 
#-------------------------------------------------------

#*******************************************************************************
$excp= "mcr_exception.txt";     # Send the exception messages to this filepath
 
#*************************************************************************
#* sub ecalc **
#**************
sub ecalc {
  local($_)=shift;              # Now $_ holds the current line
  local($res)=0;
  local($std)='not assigned'; 
                                # Search at each line for expression /.../
  if(/CALL_FAILED/)
	{ $res=1; }  	 	# Call failed!! -> FAIL
  if((/userid=\(n\/a\)/) and (/ip=0\.0\.0\.0/))
	{ $res=2; }      	# Should increment $resh{2} for NoUsr
				# -> userid=NO ip=NO                                 
  if(!(/userid=\(n\/a\)/) and (/ip=0\.0\.0\.0/))
  	{ $res=3; }             # Should increment $resh{3} for No_Ip
				# -> userid=YES ip=NO 	
  if((/userid=\(n\/a\)/) and !(/ip=0\.0\.0\.0/))
       	{ $res=4;               # This is an exception !!! 
          open(EXCP, ">> $excp") || die "can't open $excp !\n";
          print  EXCP "$_";     # we have no userid but do have ip !
          close(EXCP); }        # Should copy the message line to a different file
                                # "mcr_exception.txt"
                                # also increment $resh{4} for Excep for later use, perhaps.
				# -> userid=NO ip=YES 	
                                # If none of the above has happend,
                                # then $res=0 remains unchanged. This means
                                # userid and ip both are available, thus call is OK
                                # therefore, should increment $resh{0} for OK
				# -> userid=YES ip=YES -> OK
  if(/std=([^ ]+)\, /) { 	# Regular expression grabs Modem standard i.e. 
    $std=$1;			# any characters a plus followed by a comma and 
  };				# a space. Assigns the value to special var. $1
  
  if(length($std)<1) {	 	# If length of $std is less than 1 std 'not assigned'
    $std='not assigned';        # for ex: length($std)=5 for V.XX+
  } ;
  $_=$std;
  s/^(V\.[0-9]{2}).*$/$1/; 	# Substitution
  s/^K56Flx.*$/KFlex/;	   	# Substitution
  $stds{$_}++;			# Increments corresponding cntr for this element in the stds hash
  
  return($res);			# Return the result to main
}


###############**********************************************************************
#*  main     **
#**************

(%stds,%resh)=();
for('KFlex','V.32','V.34','V.90') {$stds{$_}=0;};
for(0..7) {$resh{$_}=0;};
$tic=0;

$tic=$ARGV[0];			# Get the time_stamp from the command line
                                # passed by the caller or parent process, 

@lin=<STDIN>;
$count=($#lin)+1;

for(@lin) {
  local($r)=ecalc($_);	# The return of ecalc is $r
  $resh{$r}++;	
}

$other=$count-$stds{'V.90'}-$stds{'KFlex'}-$stds{'V.34'}-$stds{'V.32'};

#**************************************************************************************
#*give output**
#**************

# Comma separated 
print STDOUT
"$tic,$count,$resh{0},$resh{1},$resh{2},$resh{3},$stds{'V.90'},$stds{'KFlex'},$stds{'V.34'},$stds{'V.32'},$other\n";

#*****************************************  END **************************************

