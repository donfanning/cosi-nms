#!/opt/local/bin/gawk -f
# COSI: Vadim Zakharine, Access Team
# ver. 0.0

BEGIN {
 total = 0
}

/Disconnect Reason Info:( )+\(0x/ {
 total++
 for(i=1; $i !~ /^\(0x/; i++) {}
 dr[$i]++
}

END {
 for(i in dr) {
  printf("%6s:00: %5u \(%6.2f\%\)\n", i, dr[i], (dr[i] * 100) / total)

  if(i ~ /^\(0x0/) {
   printf("%6s:10:  UNUSED\n", i)
  }
  else if(i ~ /\(0x1F..\)$/) {
   printf("%6s:10:  Host requested disconnect\n", i)
  }
  else if(i ~ /^\(0x2...\)$/) {
   printf("%6s:10:  UNUSED\n", i)
  }
  else if(i ~ /^\(0x4...\)$/) {
   printf("%6s:10:  Other situations\n", i)
  }
  else if(i ~ /^\(0x6...\)$/) {
   printf("%6s:10:  During call setup, CSR affected\n", i)
  }
  else if(i ~ /^\(0x8...\)$/) {
   printf("%6s:10:  In data mode, received data flushed, CSR not affected\n",
    i)
  }
  else if(i ~ /^\(0xA...\)$/) {
   printf("%6s:10:  In data mode, received data not flushed, CSR not affected\n",
    i)
  }
  else if(i ~ /^\(0xC...\)$/) {
   printf("%6s:10:  In data mode, transmitted data flushed, CSR not affected\n",
    i)
  }
  else if(i ~ /\(0xDF..\)$/) {
   printf("%6s:10:  Host requested disconnect\n", i)
  }
  else if(i ~ /^\(0xE...\)$/) {
   printf("%6s:10:  In data mode, transmitted data not flushed, CSR not affected",
    i)
  }

  if(i ~ /^\(0x.0..\)$/) {
   printf("%6s:20:  General disconnect reason\n", i)
  }
  else if(i ~ /^\(0x.1..\)$/) {
   printf("%6s:20:  Condition reported by DSP\n", i)
  }
  else if(i ~ /^\(0x.2[012].\)$/) {
   printf("%6s:20:  Local EC condition\n", i)
  }
  else if(i ~ /^\(0x.2[34].\)$/) {
   printf("%6s:20:  PIAFS specific condition\n", i)
  }
  else if(i ~ /\(0x.3..\)$/) {
   printf("%6s:20:  Unknown EC command from client\n", i)
   printf("%6s:21:  Command code is in last 2 digits\n", i)
  }
  else if(i ~ /\(0x.4..\)$/) {
   printf("%6s:20:  EC conditions indicated by client with LAPM FRMR\n",
    i)
   printf("%6s:21:  Command code is in last 2 digits", i)
  }
  else if(i ~ /\(0x.5..\)$/) {
   printf("%6s:20:  EC condition indicated by client with MNP LD\n", i)
  }
  else if(i ~ /\(0x.6..\)$/) {
   printf("%6s:20:  EC condition indicated by client with PIAFS DataLinkRelease",
    i)
  }
  else if(i ~ /\(0x.7..\)$/) {
   printf("%6s:20:  New DR class\n", i)
  }

  if(i ~ /^\(0x.001\)$/) {
   printf("%6s:30:  SOFTWARE_RESET command from host. No reason available\n", i)
  }
  else if(i ~ /^\(0x.002\)$/) {
   printf("%6s:30:  EC layer termination \(catch-all\)\n", i)
  }
  else if(i ~ /^\(0x.003\)$/) {
   printf("%6s:30:  MNP5 decompression received illegal token\n", i)
  }
  else if(i ~ /^\(0x.004\)$/) {
   printf("%6s:30:  V.42bis\/V.44 decompression received illegal token\n", i)
  }
  else if(i ~ /^\(0x.005\)$/) {
   printf("%6s:30:  Bad coprocessor state variable. Mica software error\n", i)
  }
  else if(i ~ /^\(0x.006\)$/) {
   printf("%6s:20:  ATH command\n", i)
  }
  else if(i ~ /^\(0x.007\)$/) {
   printf("%6s:30:  AT \"any key\" dial abort\n", i)
  }
  else if(i ~ /^\(0x.008\)$/) {
   printf("%6s:30:  Too long to complete connect \(S7\)\n", i)
  }
  else if(i ~ /^\(0x.009\)$/) {
   printf("%6s:30:  DSP reset \(command\/internal\/spontaneous\)\n", i)
  }
  else if(i ~ /^\(0x.00A\)$/) {
   printf("%6s:30:  Received V.42bis\/V.44 STEPUP makes current size exceed negotiated N1 maximum",
    i)
  }
  else if(i ~ /^\(0x.00B\)$/) {
   printf("%6s:30:  Received V.42bis codeword is equal to next empty entry",
    i)
  }
  else if(i ~ /^\(0x.00C\)$/) {
   printf("%6s:30:  Received V.42bis\/V.44 codeword is greater than next empty entry",
    i)
  }
  else if(i ~ /^\(0x.00D\)$/) {
   printf("%6s:30:  Received V.42bis\/V.44 reserved command\n", i)
  }
  else if(i ~ /^\(0x.00E\)$/) {
   printf("%6s:30:  Received V.44 STEPUP makes ordinal size exceed 8\n", i)
  }
  else if(i ~ /^\(0x.00F\)$/) {
   printf("%6s:30:  Received V.44 codeword is not in dictionary reset after Rx node tree was full",
    i)
  }
  else if(i ~ /^\(0x.010\)$/) {
   printf("%6s:30:  Received V.44 codeword is not in dictionary reset after Rx history was full",
    i)
  }
  else if(i ~ /^\(0x.011\)$/) {
   printf("%6s:30:  Received V.42bis\/V.44 codeword exceeds maximum negotiated string size",
    i)
  }
  else if(i ~ /^\(0x.012\)$/) {
   printf("%6s:30:  V.44 negotiation error\n", i)
  }
  else if(i ~ /^\(0x.013\)$/) {
   printf("%6s:30:  V.44 compression error\n", i)
  }
  else if(i ~ /^\(0x.100\)$/) {
   printf("%6s:30:  Carrier lost\n", i)
  }
  else if(i ~ /^\(0x.101\)$/) {
   printf("%6s:30:  No Answer Back Tone, not a modem?\n", i)
  }
  else if(i ~ /^\(0x.102\)$/) {
   printf("%6s:30:  Incompatible modulation or bad line\n", i)
  }
  else if(i ~ /^\(0x.103\)$/) {
   printf("%6s:30:  Too many retrains \(S40\) or speedshifts\n", i)
   printf("%6s:30:   bad line or remote disconnect\n", i)
  }
  else if(i ~ /^\(0x.104\)$/) {
   printf("%6s:30:  End of Answer-Back Tone not detected. V.8bis or excessive line noise during V.34 training",
   i)
  }
  else if(i ~ /^\(0x.106\)$/) {
   printf("%6s:30:  SS7\/COT operation failed, T8\/T24 timeout waiting for tone on",
    i)
  }
  else if(i ~ /^\(0x.107\)$/) {
   printf("%6s:30:  SS7\/COT operation failed,T8\/T24 timeout waiting for tone off",
    i)
  }
  else if(i ~ /^\(0x.108\)$/) {
   printf("%6s:30:  MOH clear down request by client modem", i)
  }
  else if(i ~ /^\(0x.109\)$/) {
   printf("%6s:30:  MOH timeout value reached", i)
  }
  else if(i ~ /^\(0x.201\)$/) {
   printf("%6s:30:  \n", i)
  }
  else if(i ~ /^\(0x.201\)$/) {
   printf("%6s:30:  \n", i)
  }
  else if(i ~ /^\(0x.201\)$/) {
   printf("%6s:30:  \n", i)
  }
  else if(i ~ /^\(0x.204\)$/) {
   printf("%6s:30:  Too many EC consecutive retransmissions\n", i)
  }
  else if(i ~ /^\(0x.205\)$/) {
   printf("%6s:30:  Inactivity timeout, MNP LD sent\n", i)
  }
  else if(i ~ /^\(0x.206\)$/) {
   printf("%6s:30:  Protocol error \(catch-all\)\n", i)
  }
  else if(i ~ /^\(0x.210\)$/) {
   printf("%6s:30:  No EC fallback protocol available \(S25\)\n", i)
  }
  else if(i ~ /^\(0x.211\)$/) {
   printf("%6s:30:  Never received XID, no client LAPM support?\n", i)
  }
  else if(i ~ /^\(0x.212\)$/) {
   printf("%6s:30:  Received LAPM XID incompatible with local settings\n", i)
  }
  else if(i ~ /^\(0x.220\)$/) {
   printf("%6s:30:  Received DISC, normal LAPM termination\n", i)
  }
  else if(i ~ /^\(0x.221\)$/) {
   printf("%6s:30:  Received DM, client disconnecting?\n", i)
  }
  else if(i ~ /^\(0x.222\)$/) {
   printf("%6s:30:  Received bad sequence number \(MNP LD or LAPM FRMR sent\)",
   i)
  }
  else if(i ~ /^\(0x.223\)$/) {
   printf("%6s:30:  Received SABME in STEADY, client reset?\n", i)
  }
  else if(i ~ /^\(0x.224\)$/) {
   printf("%6s:30:  Received LAPM XID in STEADY, client reset?\n", i)
  }
  else if(i ~ /^\(0x.225\)$/) {
   printf("%6s:30:  Received MNP LR in STEADY, client reset?\n", i)
  }
  else if(i ~ /^\(0x.230\)$/) {
   printf("%6s:30:  PIAFS\n", i)
  }
  else if(i ~ /^\(0x.231\)$/) {
   printf("%6s:30:  PIAFS\n", i)
  }
  else if(i ~ /^\(0x.232\)$/) {
   printf("%6s:30:  PIAFS\n", i)
  }
  else if(i ~ /^\(0x.233\)$/) {
   printf("%6s:30:  PIAFS\n", i)
  }
  else if(i ~ /^\(0x.234\)$/) {
   printf("%6s:30:  PIAFS\n", i)
  }
  else if(i ~ /^\(0x.235\)$/) {
   printf("%6s:30:  PIAFS\n", i)
  }
  else if(i ~ /^\(0x.236\)$/) {
   printf("%6s:30:  PIAFS\n", i)
  }
  else if(i ~ /^\(0x.237\)$/) {
   printf("%6s:30:  PIAFS\n", i)
  }
  else if(i ~ /^\(0x.238\)$/) {
   printf("%6s:30:  PIAFS\n", i)
  }
  else if(i ~ /^\(0x.239\)$/) {
   printf("%6s:30:  PIAFS\n", i)
  }
  else if(i ~ /^\(0x.23A\)$/) {
   printf("%6s:30:  PIAFS\n", i)
  }
  else if(i ~ /^\(0x.23B\)$/) {
   printf("%6s:30:  PIAFS\n", i)
  }
  else if(i ~ /^\(0x.23C\)$/) {
   printf("%6s:30:  PIAFS\n", i)
  }
  else if(i ~ /^\(0x.23D\)$/) {
   printf("%6s:30:  PIAFS\n", i)
  }
  else if(i ~ /^\(0x.23E\)$/) {
   printf("%6s:30:  PIAFS\n", i)
  }
  else if(i ~ /^\(0x.23F\)$/) {
   printf("%6s:30:  PIAFS\n", i)
  }
  else if(i ~ /^\(0x.240\)$/) {
   printf("%6s:30:  PIAFS\n", i)
  }
  else if(i ~ /^\(0x.241\)$/) {
   printf("%6s:30:  PIAFS\n", i)
  }
  else if(i ~ /^\(0x.242\)$/) {
   printf("%6s:30:  PIAFS\n", i)
  }
  else if(i ~ /^\(0x.243\)$/) {
   printf("%6s:30:  PIAFS\n", i)
  }
  else if(i ~ /^\(0x.244\)$/) {
   printf("%6s:30:  PIAFS\n", i)
  }
  else if(i ~ /^\(0x.F00\)$/) {
   printf("%6s:30:  Non-specific\n", i)
  }
  else if(i ~ /^\(0x.F01\)$/) {
   printf("%6s:30:  Dialed number busy\n", i)
  }
  else if(i ~ /^\(0x.F02\)$/) {
   printf("%6s:30:  No answer\n", i)
  }
  else if(i ~ /\(0x.401\)$/) {
   printf("%6s:30:  Bad command\n", i)
  }
  else if(i ~ /\(0x.403\)$/) {
   printf("%6s:30:  U frame data field not permitted or incorrect length\n", i)
  }
  else if(i ~ /\(0x.404\)$/) {
   printf("%6s:30:  Data field lenght > N401, but good FCS\n", i)
  }
  else if(i ~ /\(0x.408\)$/) {
   printf("%6s:30:  Bad N(R)\n", i)
  }
  else if(i ~ /\(0x.501\)$/) {
   printf("%6s:30:  Client never received our LR\n", i)
  }
  else if(i ~ /\(0x.502\)$/) {
   printf("%6s:30:  Our LR has bad parameter #1\n", i)
  }
  else if(i ~ /\(0x.503\)$/) {
   printf("%6s:30:  Our LR was incompatible with client's configuration\n", i)
  }
  else if(i ~ /\(0x.504\)$/) {
   printf("%6s:30:  Client saw too many consecutive retransmissions\n", i)
  }
  else if(i ~ /\(0x.505\)$/) {
   printf("%6s:30:  Client's inactivity timer expired\n", i)
  }
  else if(i ~ /\(0x.506\)$/) {
   printf("%6s:30:  Protocol error\n", i)
  }
  else if(i ~ /\(0x.5FF\)$/) {
   printf("%6s:30:  Normal disconnect\n", i)
  }
  else if(i ~ /\(0x.610\)$/) {
   printf("%6s:30:  \"Normal\" class release\n", i)
  }
  else if(i ~ /\(0x.611\)$/) {
   printf("%6s:30:  \"Normal\" class release, data link continuation forbidden",
    i)
  }
  else if(i ~ /\(0x.612\)$/) {
   printf("%6s:30:  \"Normal\" class release, data link continuation\n", i)
  }
  else if(i ~ /\(0x.61.\)$/) {
   printf("%6s:30:  \"Normal\" class, other\n", i)
  }
  else if(i ~ /\(0x.628\)$/) {
   printf("%6s:30:  \"Resource use not possible\" class, DTE busy\n", i)
  }
  else if(i ~ /\(0x.629\)$/) {
   printf("%6s:30:  \"Resource use not possible\" class\n", i)
   print(", temporary obstruction")
  }
  else if(i ~ /\(0x.62.\)$/) {
   printf("%6s:30:  \"Resource use not possible\" class, other\n", i)
  }
  else if(i ~ /\(0x.641\)$/) {
   printf("%6s:30:  \"Service not yet provided\" class, parameter indication",
    i)
  }
  else if(i ~ /\(0x.64.\)$/) {
   printf("%6s:30:  \"Service not yet provided\" class, other\n", i)
  }
  else if(i ~ /\(0x.658\)$/) {
   printf("%6s:30:  \n", i)
  }
  else if(i ~ /\(0x.65.\)$/) {
   printf("%6s:30:  \n", i)
  }
  else if(i ~ /\(0x.660\)$/) {
   printf("%6s:30:  \"Sequence error\" class, essential parameters insufficient",
    i)
  }
  else if(i ~ /\(0x.661\)$/) {
   printf("%6s:30:  \"Sequence error\" class, information content undefined or not yet provided",
    i)
  }
  else if(i ~ /\(0x.665\)$/) {
   printf("%6s:30:  \"Sequence error\" class, ARQ condition and signal not matched",
    i)
  }
  else if(i ~ /\(0x.666\)$/) {
   printf("%6s:30:  \"Sequence error\" class, timer expires\n", i)
  }
  else if(i ~ /\(0x.66.\)$/) {
   printf("%6s:30:  \"Sequence error\" class, other\n", i)
  }
  else if(i ~ /\(0x.671\)$/) {
   printf("%6s:30:  \"Other pecularities\" class, during voice call\n", i)
  }
  else if(i ~ /\(0x.67.\)$/) {
   printf("%6s:30:  \"Other pecularities\" class, other\n", i)
  }
  else if(i ~ /^\(0x.F00\)$/) {
   printf("%6s:30:  Non-specific host disconnect\n", i)
  }
  else if(i ~ /^\(0x.F01\)$/) {
   printf("%6s:30:  Dialed number busy\n", i)
  }
  else if(i ~ /^\(0x.F02\)$/) {
   printf("%6s:30:  Dialed number didn't answer\n", i)
  }
  else if(i ~ /^\(0x.F03\)$/) {
   printf("%6s:30:  \"Virtual\" DTR dropped\n", i)
  }
  else if(i ~ /^\(0x.F04\)$/) {
   printf("%6s:30:  ATH command \(detected by host\)\n", i)
  }
  else if(i ~ /^\(0x.F05\)$/) {
   printf("%6s: Host couldn't access telco network\n", i)
  }
  else if(i ~ /^\(0x.F06\)$/) {
   printf("%6s:30:  Network indicated\n", i)
  }
  else if(i ~ /^\(0x.F07\)$/) {
   printf("%6s:30:  LAC terminated SS7\/COT operation\n", i)
  }
  else if(i ~ /^\(0x.F08\)$/) {
   printf("%6s:30:  SS7\/COT terminated by T8\/T24 timeout\n", i)
  }
  else if(i ~ /^\(0x.FFF\)$/) {
   printf("%6s:30:  Unsolicited TERMINATING\n", i)
  }
  else if(i ~ /^\(0x.F..\)$/) {
   printf("%6s:30:  Other, reason is in last 2 digits\n", i)
  }
 }
 printf("Total disconnects = %u", total)
}