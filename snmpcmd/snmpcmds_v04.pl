<!-- #BeginLibraryItem "/lwt-start.lbi" -->
<!-- Version 0.1 by Kris Thompson -->
<!-- Updated for release by rcl 070601-->

<!-- HTMLHEAD -->
<html>
<HEAD>
<TITLE>SNMP Commander</TITLE>
</HEAD>
<body bgcolor="#FFFFFF" background="/graphics/ss7.gif">

<table BORDER="1" WIDTH="650">
<tr>
    <td WIDTH="90" HEIGHT="92">
         <img SRC="/graphics/sup_spot.jpg" height=92 width=90 align=CENTER>
    </td>

    <td HEIGHT="92">
         <img SRC="/graphics/snmpcmdr_bn.gif">
         <p><font size=-1><i><a href="http://mccain.ots.utexas.edu/coe/lwt">Other Lightweight Tools</a> by <a href="http://mccain.ots.utexas.edu">CoE-IAE</a></i></font>
    </td>
</tr>

<tr>
<td VALIGN=TOP WIDTH="90">
<!-- #BeginLibraryItem "/leftmenu-01.lbi" -->
<b>Useful LInks:</b><br><p>
<font size="-1" face="Verdana, Arial, Helvetica, sans-serif">
<a href="http://cosi-nms.sf.net">COSI Home</a><br><p>
<a href="http://sourceforge.net/projects/cosi-nms">COSI Project Page</a><br><p>
<a href="http://sourceforge.net">SourceForge Home</a><br><p>
<a href="http://mccain.ots.utexas.edu">UT CoE-IAE</a><br>
</font>

<!-- #EndLibraryItem "/leftmenu-01.lbi" -->
</td>

<td VALIGN=TOP>
<h2>SNMP Commander, Version 0.4</h2>
<form method="GET" enctype="application/x-www-form-urlencoded">
  <p><b> Select SNMP Command * OID: <select name="cmdreq"><option>walk system</option>
<option>walk cisco.lsystem</option>
<option>table entPhysicalTable</option>
<option>table entLogicalTable</option>
<option>walk chassis</option>
<option>table cdspCardStatusTable</option>
<option>get ifNumber</option>
<option>table ifTable</option>
<option>table lifTable</option>
<option>table dsx1TotalTable</option>
<option>table dsx1FarEndCurrentTable</option>
<option>table dsx1FracTable</option>
<option>walk ip</option>
<option>table ipNetToMediaTable</option>
<option>walk icmp</option>
<option>walk tcp</option>
<option>table tcpConnTable</option>
<option>walk udp</option>
<option>table udpTable</option>
<option>table cQIfTable</option>
<option>table cQStatsTable</option>
<option>table rs232PortTable</option>
<option>table rs232AsyncPortTable</option>
<option>table rs232SyncPortTable</option>
<option>table rs232InSigTable</option>
<option>table rs232OutSigTable</option>
<option>table ltsLineTable</option>
<option>table cdpInterfaceTable</option>
<option>table cdpCacheTable</option>
<option>table isdnBasicRateTable</option>
<option>table isdnBearerTable</option>
<option>table isdnSignalingTable</option>
<option>table isdnSignalingStatsTable</option>
<option>table isdnLapdTable</option>
<option>table isdnEndpointTable</option>
<option>table isdnDirectoryTable</option>
<option>table ccasDs1IfCfgTable</option>
<option>table dialCtlPeer</option>
<option>table demandNbrTable</option>
<option>walk ciscoCallResourcePoolMIB</option>
<option>table cmmFaxGeneralCfg</option>
<option>table ciscoCallHistoryTable</option>
<option>table cpmDS0UsageTable</option>
<option>get ISDNCfgBChanInUseForAnalog</option>
<option>get ISDNCfgBChannelsInUse</option>
<option>get cpmActiveDS0s</option>
<option>get cpmPPPCalls</option>
<option>get cpmV120Calls</option>
<option>get cpmV110Calls</option>
<option>get cpmActiveDS0sHighWaterMark</option>
<option>table DS1DS0 Usage Table</option>
<option>get cpmSW56CfgBChannelsInUse</option>
<option>walk cpmCallFailure</option>
<option>table cpmActiveCallSummaryTable</option>
<option>get cpmCallHistorySummaryTableMaxLength</option>
<option>get cpmCallHistorySummaryRetainTimer</option>
<option>table cpmCallHistorySummaryTable</option>
<option>walk cmSystemInfo</option>
<option>table cmGroupTable</option>
<option>table cmGroupMemberTable</option>
<option>table cmLineStatusTable</option>
<option>table cmLineConfigTable</option>
<option>table cmLineStatisticsTable</option>
<option>table cmLineSpeedStatisticsTable</option>
<option>walk CISCO-AAA-SERVER-MIB</option>
<option>walk CISCO-AAA-SESSION-MIB</option>
<option>walk ciscoAAAServerCapability</option>
<option>get cvpdnTunnelTotal</option>
<option>get cvpdnSessionTotal</option>
<option>get cvpdnDeniedUsersTotal</option>
<option>table cvpdnSystemTable</option>
<option>table cvpdnTunnelTable</option>
<option>table cvpdnTunnelAttrTable</option>
<option>table cvpdnTunnelSessionTable</option>
<option>table cvpdncvpdnSessionAttrTable</option>
<option>table cvpdnUserToFailHistInfoTable</option>
<option>table rttMonApplSupportedRttTypesTable</option>
<option>table rttMonApplSupportedProtocolsTable</option>
<option>walk expressionMIB</option>
<option>walk snmpFrameworkMIB</option>
<option>walk snmp</option>
<option>walk rmon</option>
<option>table ccmHistoryEventTable</option>
<option>walk clogBasic</option>
<option>table clogHistoryTable</option>
<option>walk ciscoFtpClientMIB</option>
<option>table ciuIfStaticConfigTable</option>
<option selected></option>
</select><br>
      Select SNMP Agent:    <select name="agent"><option>maui-nas-01</option>
<option>maui-nas-05</option>
<option>maui-nas-06</option>
<option>maui-rtr-02</option>
<option>maui-rtr-01</option>
<option>maui-nas-02</option>
<option>maui-nas-03</option>
<option>maui-nas-04</option>
<option>maui-rtr-03</option>
<option>maui-rtr-04</option>
<option>maui-rtr-05</option>
<option>maui-rtr-06</option>
<option>maui-robo-01</option>
<option>maui-mgc-01</option>
<option>maui-mgc-02</option>
<option>maui-vgw-01</option>
<option>travis-nas-01.the.net</option>
<option>monica.ots.utexas.edu</option>
<option>krist-isdn</option>
<option>nas-06-pool23</option>
</select>   Go: <input type="submit" value="Submit">
  </b></p>
</form>
<hr width="650" align="left">
  <table border="1" bgcolor="#FFFF99" width="100%"> 
      <tr>
         <td width="100%">
            <b>Program messages:</b>
            <pre width="80"></pre>
         </td>
      </tr>
  </table>

  <table border="1" bgcolor="#AAFFFF" width="100%"> 
      <tr>
         <td width="100%">
            <pre width="80">
            
            </pre>
         </td>
      </tr>
  </table>  
</td>
</tr>
</table>
<font size = -1>Feedback: <a href='mailto:coe-iae@cisco.com'>coe-iae@cisco.com</a></font>
</body>
</html>
