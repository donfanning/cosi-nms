#!/opt/local/bin/gawk -f
# COSI: Vadim Zakharine, Access Team
# ver. 0.0

BEGIN {
 total = 0
}

/Disconnect Reason Info/ {
 total++
 for(i = 1; ($i !~ /^0x/) && (i <= NF); i++) {}
 dr[$i]++
}

END {
 for(i in dr) {
  printf("%6-s:00: %5u \(%6.2f\%\)\n",
   i, dr[i], (dr[i] * 100) / total)

  if(i ~ /^0x0../) {
   printf("%6-s:10: General disconnect reason\n", i)
  }
  else if(i ~ /^0x1../) {
   printf("%6-s:10: Condition reported by SPE\n", i)
  }
  else if(i ~ /^0x2../) {
   printf("%6-s:10: Local EC condition\n", i)
  }
  else if(i ~ /^0x3../) {
   printf("%6-s:10: Received unknown command \(last 2 digits\). LD or FRMR sent\n",
    i)
  }
  else if(i ~ /^0x4../) {
   printf("%6-s:10: EC condition indicated by client in FRMR\n", i)
  }
  else if(i ~ /^0x5../) {
   printf("%6-s:10: EC condition indicated by client in LD\n", i)
  }
  else if(i ~ /^0x1F../) {
   printf("%6-s:10: Host initiated disconnect\n", i)
  }
  else {
   printf("%6-s:10: Unidentified class\n", i)
  }

  if(i ~ "0x001") {
   printf("%6-s:20: Host issued a SOFTWARE_RESET command \(no host reason is available\)\n", i)
  }
  else if(i ~ "0x002") {
   printf("%6-s:20: EC layer termination \(catch-all\)\n", i)
  }
  else if(i ~ "0x003") {
   printf("%6-s:20: MNP5 decompression task received illegal token in data stream\n", i)
  }
  else if(i ~ "0x004") {
   printf("%6-s:20: V.42bis or V.44 decompression task received illegal token in data stream\n", i)
  }
  else if(i ~ "0x005") {
   printf("%6-s:20: <reserved>\n", i)
  }
  else if(i ~ "0x006") {
   printf("%6-s:20: ATH command \(detected by local modem\)\n", i)
  }
  else if(i ~ "0x007") {
    printf("%6-s:20: AT mode \"any key\" abort of dial command\n", i)
  }
  else if(i ~ "0x008") {
   printf("%6-s:20: Took too long to complete connect\n", i)
  }
  else if(i ~ "0x009") {
   printf("%6-s:20: DSP was reset\n", i)
  }
  else if(i ~ "0x00C") {
   printf("%6-s:20: Received V.42bis or V.44 STEPUP codeword causes current size C2 exceeded negotiated maximum N1\n", i)
  }
  else if(i ~ "0x00D") {
   printf("%6-s:20: Received V.42bis or V.44 codeword is equal to next empty entry C1\n", i)
  }
  else if(i ~ "0x00E") {
   printf("%6-s:20: Received V.42bis or V.44 codeword is greater next empty entry C1\n", i)
  }
  else if(i ~ "0x00F") {
   printf("%6-s:20: V.42bis or V.44 received reserved command code\n", i)
  }
  else if(i ~ "0x010") {
   printf("%6-s:20: Received V.42bis or V.44 STEPUP codeword causes ordinal size C5 exceeded 8\n", i)
  }
  else if(i ~ "0x011") {
   printf("%6-s:20: V.42bis or V.44 negotiation error\n", i)
  }
  else if(i ~ "0x012") {
   printf("%6-s:20: V.42bis or V.44 compression error\n", i)
  }

  else if(i ~ "0x100") {
   printf("%6-s:20: Carrier lost\n", i)
  }
  else if(i ~ "0x101") {
   printf("%6-s:20: No answer-back tone. Probably not a modem\n", i)
  }
  else if(i ~ "0x102") {
   printf("%6-s:20: Incompatible modulation or bad line while training up\n", i)
  }
  else if(i ~ "0x103") {
   printf("%6-s:20: Too many consecutive retrains or speed-shifts\n", i)
  }
  else if(i ~ "0x104") {
   printf("%6-s:20: No answer-back tone. Negotiation failure or noise during V.34 training\n", i)
  }
  else if(i ~ "0x105") {
   printf("%6-s:20: SS7/COT operation completed successfully\n", i)
  }
  else if(i ~ "0x106") {
   printf("%6-s:20: SS7/COT operation failed: T8/T24 timeout waiting for tone on\n", i)
  }
  else if(i ~ "0x107") {
   printf("%6-s:20: SS7/COT operation failed: T8/T24 timeout waiting for tone off\n", i)
  }
  else if(i ~ "0x108") {
   printf("%6-s:20: MOH clear down by modem\n", i)
  }
  else if(i ~ "0x109") {
   printf(" %6-s:20: MOH timeout value reached\n", i)
  }

  else if(i ~ "0x201") {
   printf("%6-s:20: During negotiation LR frame not received. Client doesn't support MNP?\n", i)
  }
  else if(i ~ "0x202") {
   printf("%6-s:20: MNP LR frame had bad PARAM1\n", i)
  }
  else if(i ~ "0x203") {
   printf("%6-s:20: Received MNP LR frame is incompatible with local settings\n", i)
  }
  else if(i ~ "0x204") {
   printf("%6-s:20: Too many consecutive retransmissions in EC\n", i)
  }
  else if(i ~ "0x205") {
   printf("%6-s:20: Inactivity timeout, LD \(inactivity\) sent\n", i)
  }
  else if(i ~ "0x206") {
   printf("%6-s:20: EC protocol error \(catch-all\)\n", i)
  }
  else if(i ~ "0x210") {
   printf("%6-s:20: No EC fallback protocol available\n", i)
  }
  else if(i ~ "0x211") {
   printf("%6-s:20: During negotiation MNP XID frame not received\n", i)
  }
  else if(i ~ "0x212") {
   printf("%6-s:20: Received MNP XID frame is incompatible with local settings\n", i)
  }
  else if(i ~ "0x220") {
   printf("%6-s:20: Normal LAP-M disconnect\n", i)
  }
  else if(i ~ "0x221") {
   printf("%6-s:20: DM frame received. Client disconnects?\n", i)
  }
  else if(i ~ "0x222") {
   printf("%6-s:20: Bad receive sequence/ACK number received. LD or FRMR sent\n", i)
  }
  else if(i ~ "0x223") {
   printf("%6-s:20: Received SABME frame in steady state. Client reset?\n", i)
  }
  else if(i ~ "0x224") {
   printf("%6-s:20: Received MNP XID frame in steady state. Client reset?\n", i)
  }
  else if(i ~ "0x225") {
   printf("%6-s:20: Received MNP LR frame in steady state. Client reset?\n", i)
  }

  else if(i ~ "0x401") {
   printf("%6-s:20: Client reports bad command\n", i)
  }
  else if(i ~ "0x403") {
   printf("%6-s:20: Client reports data field not permitted or incorrect length \(U frames\)\n", i)
  }
  else if(i ~ "0x404") {
   printf("%6-s:20: Client reports data field length > N401, but good FCS\n", i)
  }
  else if(i ~ "0x408") {
   printf("%6-s:20: Client reports bad N\(R\)\n", i)
  }
  else if(i ~ "0x501") {
   printf("%6-s:20: Client never received MNP LR frame\n", i)
  }
  else if(i ~ "0x502") {
   printf("%6-s:20: Client reports MNP LR frame has bad parameter #1\n", i)
  }
  else if(i ~ "0x503") {
   printf("%6-s:20: Client reports MNP LR frame is incompatible with its configuration\n", i)
  }
  else if(i ~ "0x504") {
   printf("%6-s:20: Client reports too many consecutive EC retransmissions\n", i)
  }
  else if(i ~ "0x505") {
   printf("%6-s:20: Client reports inactivity timer expired\n", i)
  }
  else if(i ~ "0x506") {
   printf("%6-s:20: Client reports MNP error\n", i)
  }
  else if(i ~ "0x5FF") {
   printf("%6-s:20: Normal MNP disconnect\n", i)
  }

  else if(i ~ "0x1F00") {
   printf("%6-s:20: Non-specific host disconnect\n", i)
  }
  else if(i ~ "0x1F01") {
   printf("%6-s:20: Number busy\n", i)
  }
  else if(i ~ "0x1F02") {
   printf("%6-s:20: Number doesn't answer\n", i)
  }
  else if(i ~ "0x1F03") {
    printf("%6-s:20: \"Virtual\" DTR dropped\n", i)
  }
  else if(i ~ "0x1F04") {
   printf("%6-s:20: ATH command\n", i)
  }
  else if(i ~ "0x1F05") {
   printf("%6-s:20: No access to telco network\n", i)
  }
  else if(i ~ "0x1F06") {
   printf("%6-s:20: Network indicated disconnect\n", i)
  }
  else if(i ~ "0x1F07") {
   printf("%6-s:20: NAS terminated SS7/COT operation\n", i)
  }
  else if(i ~ "0x1F08") {
   printf("%6-s:20: SS7/COT terminated by T8/T24 timeout\n", i)
  }
  else if(i ~ "0x1FFF") {
   printf("%6-s:20: Unsolicited TERMINATING\n", i)
  }

  else {
   printf("%6-s:20: Unidentified DR\n", i)
  }
 }
 printf("Total disconnects = %u", total)
}