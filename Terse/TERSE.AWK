# COSI: Vadim Zakharine, Access Team
# ver 1.0

BEGIN {
 FS="[ ,]+"
 SUBSEP = ""
 total = 0
}

/TERSE/ {
 Userid = ""
 Calling = ""
 Called = ""
 Discon = ""
 total++
 for(i=1; (Discon == "") && (i <= NF); i++) {
  if((Userid == "") && ($i ~ /^userid=/)) {
   split($i, buff, "=+")
   Userid = sprintf("\"%s\"", buff[2])
  }
  else if((Calling == "") && ($i ~ /^calling=/)) {
   split($i, buff, "=+")
   Calling = buff[2]
  }
  else if((Called == "") && ($i ~ /^called=/)) {
   split($i, buff, "=+")
   Called = sprintf(">%s", buff[2])
  }
  else if((Discon == "") && ($i ~ /^disc\(modem\)=/)) {
   split($i, buff, "=+")
   Discon = buff[2]
  }
 }
 printf("[00]%s=%s%s%s", Discon, Calling, Called, Userid)
 userstat[Calling, Called, Userid]++
 userdisc[Calling, Called, Userid, Discon]++
 modmstat[Discon]++
 for(i=1; ($i !~ /^disc/) && (i <= NF); i++) {
  if($i ~ /^%CALLRECORD/) {
   printf(" %s", $i)
  }
  else if($i ~ /^std=/) {
   printf(" %s", $i)
  }
  else if($i ~ /^prot=/) {
   printf(" %s", $i)
  }
  else if($i ~ /^b\-rate=/) {
   printf(" %s", $i)
  }
  else if($i ~ /^comp=/) {
   printf(" %s", $i)
  }
  else if($i ~ /^init\-rx\/tx=/) {
   printf(" %s", $i)
  }
  else if($i ~ /^finl\-rx\/tx=/) {
   printf(" %s", $i)
  }
  else if($i ~ /^retr=/) {
   printf(" %s", $i)
  }
  else if($i ~ /sq=/) {
   printf(" %s", $i)
  }
  else if($i ~ /snr=/) {
   printf(" %s", $i)
  }
  else if($i ~ /^rx\-tx=/) {
   printf(" %s", $i)
  }
  else if($i ~ /^chars=/) {
   printf(" %s", $i)
  }
  else if($i ~ /^bad=/) {
   printf(" %s", $i)
  }
  else if($i ~ /^ec=/) {
   printf(" %s", $i)
  }
  else if($i ~ /^time=/) {
   printf(" %s", $i)
  }
  else if($i ~ /^finl\-state=/) {
   printf(" %s", $i)
  }
 }
 while(i <= NF) {
  printf(" %s", $i)
  i++
 }
 printf("\n")
}

END {
 Userid = 0
 for(Calling in userstat) {
  Userid++
  for(Called in modmstat) {
   if(userdisc[Calling, Called] != "") {
    printf("[10]%s=%s : %u (user %.2f\%, total %.2f\%)\n",
     Calling, Called, userdisc[Calling, Called],
     userdisc[Calling, Called]*100/userstat[Calling],
     userdisc[Calling, Called]*100/modmstat[Called])
   }
  }
 }
 for(i in modmstat) {
  printf("[20]% 4s : %u (%.2f\%)\n", i, modmstat[i], modmstat[i]*100/total)
 }
 printf("[30]Total: %u terse records, %u users\n", total, Userid)
}