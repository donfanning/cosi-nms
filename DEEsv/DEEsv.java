/*-
 * Copyright (c) 2002 Joe Marcus Clarke <marcus@marcuscom.com>
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS'' AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
 * OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 * OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 * SUCH DAMAGE.
 *
 * $Id$
 */

package com.marcuscom.deesv;

import java.io.*;
import java.util.*;

import org.w3c.dom.*;
import com.ibm.xml.parsers.*;
import org.xml.sax.*;

public class DEEsv {
    public final static String CWEXPORT = "cwexport";
    public final static String VERSION = "1.0";
    public final static String rcsid = "$Id$";

    public static String NMSROOT = System.getProperty("NMSROOT");
    public static String TMPDIR = System.getProperty("TMPDIR");
    public static String SEP = System.getProperty("file.separator");

    public final static String ADD_INFO = "AdditionalInformation";
    public final static String CISCO_CARD = "Cisco_Card";
    public final static String RME_PLATFORM = "RMEPlatform";
    public final static String CISCO_COMM_CONNECTOR = "Cisco_CommunicationConnector";
    public final static String SOFTWARE_IDENTITY = "SoftwareIdentity";
    public final static String CISCO_BACKPLANE = "Cisco_Backplane";
    public final static String CISCO_NETWORK_ELEMENT = "Cisco_NetworkElement";
    public final static String CISCO_CHASSIS = "Cisco_Chassis";
    public final static String CISCO_FLASH_DEVICE = "Cisco_FlashDevice";
    public final static String CISCO_FLASH_PARTITION = "Cisco_FlashPartition";
    public final static String CISCO_FLASH_FILE = "Cisco_FlashFile";
    public final static String CISCO_PHYSICAL_MEMORY = "Cisco_PhysicalMemory";
    public final static String CISCO_LOGICAL_MODULE = "Cisco_LogicalModule";
    public final static String CISCO_PORT = "Cisco_Port";
    public final static String CISCO_MEMORY_POOL = "Cisco_MemoryPool";
    public final static String CISCO_IF_ENTRY = "Cisco_IfEntry";
    public final static String CISCO_IP_PROTO_ENDPOINT = "Cisco_IPProtocolEndpoint";
    public final static String CISCO_PE_HAS_IF_ENTRY = "Cisco_PEHasIfEntry";
    public final static String CISCO_OS_ELEMENT = "Cisco_OSElement";
    public final static String IF_INSTANCE_ID = "IfInstanceID";

    // Class properties
    protected PrintStream ps = null;
    protected String tmpfilename = null;
    protected Node document = null;
    protected char separator = ',';

    // Storage Vectors for our  devices
    protected Vector devices = new Vector();

    // Hashtables used to store XML tag -> CSV header name mappings
    protected Hashtable chassisObjects = null;
    protected Hashtable backplaneObjects = null;
    protected Hashtable cardObjects = null;
    protected Hashtable softwareIdentityObjects = null;
    protected Hashtable ciscoCommunicationConnectorObjects = null;
    protected Hashtable ciscoFlashDeviceObjects = null;
    protected Hashtable ciscoFlashPartitionObjects = null;
    protected Hashtable ciscoFlashFileObjects = null;
    protected Hashtable ciscoPhysicalMemoryObjects = null;
    protected Hashtable ciscoNetworkElementObjects = null;
    protected Hashtable ciscoLogicalModuleObjects = null;
    protected Hashtable ciscoPortObjects = null;
    protected Hashtable ciscoIfEntryObjects = null;
    protected Hashtable ciscoMemoryPoolObjects = null;
    protected Hashtable ciscoOSElementObjects = null;
    protected Hashtable ciscoIPProtoEndpointObjects = null;
    protected Hashtable ciscoPEHasIfEntryObjects = null;

    public static void main(String argv[]) {
        DEEsv deesv = null;
        String outfilename = null;
        String logfilename = null;
        File outfile = null;
        File logfile = null;
        File tmp = null;
        PrintStream ps = null;
        int debugLevel = 0;
        char separator = ',';

        if (argv.length == 0) {
            usage();
            System.exit(1);
        }

        // Extract the output filename from argv.
        for (int i = 0; i < argv.length; i++) {
            if (argv[i].equals("-f")) {
                if (i == (argv.length - 1)) {
                    System.err.println("* Error * The -f flag requires an argument.");
                    usage();
                    System.exit(1);
                }
                outfilename = argv[i + 1];
                // Remove any output file name arguments.
                argv[i] = null;
                argv[i + 1] = null;
                i++;
                continue;
            }

            if (argv[i].equals("-d")) {
                if (i == (argv.length - 1)) {
                    System.err.println("* Error * The -d flag requires an argument.");
                    usage();
                    System.exit(1);
                }
                try {
                    debugLevel = Integer.parseInt(argv[i + 1]);
                }
                catch (NumberFormatException nfe) {
                    System.err.println("* Error * Debug level must be a number");
                    usage();
                    System.exit(1);
                }
                continue;
            }

            if (argv[i].equals("-sep")) {
                if (i == (argv.length - 1)) {
                    System.err.println("* Error * The -sep flag requires an argument.");
                    usage();
                    System.exit(1);
                }
                separator = argv[i + 1].charAt(0);
                // Remove this argument
                argv[i] = null;
                argv[i + 1] = null;
                i++;
                continue;
            }

            if (argv[i].equals("-l")) {
                if (i == (argv.length - 1)) {
                    System.err.println("* Error * The -l flag requires an argument.");
                    usage();
                    System.exit(1);
                }
                logfilename = argv[i + 1];
                // Remove the logfile argument
                argv[i] = null;
                argv[i + 1] = null;
                i++;
                continue;
            }

            if (argv[i].equals("-h")) {
                usage();
                System.exit(0);
            }

            if (argv[i].equals("-v")) {
                version();
                System.exit(0);
            }

            if (argv[i].equals("-p")) {
                System.err.println("");
                System.err.println("* Warning * The -p option is highly insecure and *not* recommended.");
                System.err.println("* Warning * See -u option for more details.");
                System.err.println("\n");
                continue;
            }

            if (argv[i].equals("config")) {
                System.err.println("* Error * The config command is not supported by DEEsv");
                usage();
                System.exit(1);
            }
	    else if (argv[i].startsWith("-")) {
		if (!argv[i].equals("-help") && !argv[i].equals("-m") &&
		    !argv[i].equals("-continue") &&
		    !argv[i].equals("-device") && !argv[i].equals("view") &&
		    !argv[i].equals("-input") && !argv[i].equals("-u")) {
		    System.err.println("* Fatal error * Unknown command argument OR unexpected argument: " + argv[i]);
		    System.exit(1);
		}
	    }
        }

        // Obtain a DataOutputStream to write error output.
        if (logfilename != null) {
            logfile = new File(logfilename);
            try {
                System.setErr(new PrintStream(new FileOutputStream(logfile)));
            }
            catch (Exception e) {
                System.err.println("Failed to create logfile.");
                if (debugLevel == 1) {
                    System.err.println(e.getMessage());
                }
                else if (debugLevel > 1) {
                    e.printStackTrace(System.err);
                }
                System.exit(1);
            }
        }

        // Obtain a DataOutputStream to write our CSV file.
        if (outfilename != null) {
            outfile = new File(outfilename);
            try {
                ps = new PrintStream(new FileOutputStream(outfile));
            }
            catch (Exception e) {
                System.err.println("Failed to create output file.");
                if (debugLevel == 1) {
                    System.err.println(e.getMessage());
                }
                else if (debugLevel > 1) {
                    e.printStackTrace(System.err);
                }
                System.exit(1);
            }
        }
        else {
            ps = System.out;
        }

        try {
            tmp = File.createTempFile("DEEsv_", null, new File(TMPDIR));
            runCwexport(argv, tmp.toString());
            deesv = new DEEsv(tmp.toString(), separator, ps);
            deesv.xml2CSV();
            deesv.printCSV();
            ps.close();
            System.err.close();
            tmp.delete();
        }
        catch (Exception e) {
            System.err.println("Failed to create CSV file.");
            if (debugLevel == 1) {
		if (e.getMessage() != null) {
                    System.err.println(e.getMessage());
		}
		else {
		    System.err.println("Encountered NullPointerException");
		}
            }
            else if (debugLevel > 1) {
                e.printStackTrace(System.err);
            }
            if (tmp != null && tmp.exists()) {
                tmp.delete();
            }
            if (ps != null) {
                ps.close();
            }
            System.err.close();
            System.exit(1);
        }
        System.out.println("Successfully wrote data to " + outfilename);
    }

    static void runCwexport(String[] argv, String tmp)
    throws Exception {

        Runtime r = Runtime.getRuntime();
        Process p = null;
        String args = "";
        InputStream pIn = null;

        for (int i = 0; i < argv.length; i++) {
            if (argv[i] != null) {
                args = args.concat(argv[i] + " ");

            }
        }

        args.trim();
        args += " -f " + tmp;

        p = r.exec(NMSROOT + SEP + "bin" + SEP + CWEXPORT + " " + args);
        pIn = p.getInputStream();
        byte b[] = new byte[4096];
        while (true) {
            int len = pIn.read(b);
            if (len == -1) break;
            if (len > 0) {
                String str = new String(b, 0, len);
                // XXX This is ugly.
                int idx = str.indexOf("Output file is ", 0);
                if (idx >= 0) {
                    str = str.substring(0, idx);
                }
                System.err.print(str);
		System.err.flush();
            }
        }

        p.waitFor();

        if (p.exitValue() != 0) {
            throw new Exception("cwexport command failed with exit status " +
                                p.exitValue());
        }
    }

    static void usage() {
        System.err.println("(C) Copyright 2002 MarcusCom, Inc.  All Rights Reserved");
        System.err.println("CiscoWorks 2000 command line interface for exporting inventory\ndata in CSV format.");
        System.err.println("");
        System.err.println("General syntax to run a command with arguments is");
        System.err.println("\tDEEsv <command> <arguments>");
        System.err.println("For detailed help on a command and its arguments, run");
        System.err.println("\tcwexport <command> -help");
        System.err.println("");
        System.err.println("Following is the list of commands that are supported");
        System.err.println("-v        : displays the version of DEEsv");
        System.err.println("inventory : exports invetory information from the RME database in CSV format");
        System.err.println("-h        : prints this message");
        System.err.println("");
        System.err.println("DEEsv takes the following non-cwexport arguments:");
        System.err.println("");
        System.err.println("-sep <character> : Set the separator character to <character> (default is ',')");
        System.err.println("");
        System.err.println("See the cwexport help within CiscoWorks 2000 for more information.");
    }

    static void version() {
        System.out.println("Copyright (C) 2002 MarcusCom, Inc. All Rights Reserved.");
        System.out.println("DEEsv: CSV wrapper to CiscoWorks 2000 Data Extracting Engine\ncommand line interface");
        System.out.println("        Version " + VERSION);
    }

    public DEEsv (String tmpfilename, char separator, PrintStream ps)
    throws SAXException, IOException {
        this.tmpfilename = tmpfilename;
        this.ps = ps;
        DOMParser parser = new com.ibm.xml.parsers.DOMParser();
        parser.parse(tmpfilename);
        this.document = parser.getDocument();
        this.separator = separator;

        // Populate the chassisObjects Hash
        this.chassisObjects = new Hashtable();
        chassisObjects.put("Model", "Model");
        chassisObjects.put("HardwareVersion", "Hardware Version");
        chassisObjects.put("SerialNumber", "Serial Number");
        chassisObjects.put("ChassisSystemType", "System Type");
        chassisObjects.put("NumberOfSlots", "Number Of Slots");
        chassisObjects.put("NoOfCommunicationConnectors", "No. Of Communication Connectors");

        // Populate the backplaneObjects Hash
        this.backplaneObjects = new Hashtable();
        backplaneObjects.put("BackplaneType", "Backplane Type");
        backplaneObjects.put("Model", "Backplane Model");
        backplaneObjects.put("SerialNumber", "Backplane Serial Number");

        // Populate the cardObjects Hash
        this.cardObjects = new Hashtable();
        cardObjects.put("RequiresDaughterBoard", "Requires Daughter Board");
        cardObjects.put("Model", "Model");
        cardObjects.put("SerialNumber", "Serial Number");
        cardObjects.put("LocationWithinContainer", "Chassis Slot Number");
        cardObjects.put("PartNumber", "Part Number");
        cardObjects.put("CardType", "Type");
        cardObjects.put("HardwareVersion", "HW Version");
        cardObjects.put("Description", "Description");
        cardObjects.put("OperationalStatus", "Operational Status");
        cardObjects.put("FWManufacturer", "Firmware Manufacturer");
        cardObjects.put("Manufacturer", "Manufacturer");
        cardObjects.put("NumberOfSlots", "Number Of Slots");
        cardObjects.put("NoOfCommunicationConnector", "No. Of Communication Connectors");

        // Populate the softwareIdentityObjects Hash
        this.softwareIdentityObjects = new Hashtable();
        softwareIdentityObjects.put("VersionString", "SW Version");

        // Populate the ciscoCommunicationConnectorObjects Hash
        this.ciscoCommunicationConnectorObjects = new Hashtable();
        ciscoCommunicationConnectorObjects.put("ConnectorType", "Type");
        ciscoCommunicationConnectorObjects.put("Description", "Description");

        // Populate the ciscoFlashDeviceObjects Hash
        this.ciscoFlashDeviceObjects = new Hashtable();
        ciscoFlashDeviceObjects.put("InstanceID", "Flash Device");
        ciscoFlashDeviceObjects.put("InstanceName", "Name");
        ciscoFlashDeviceObjects.put("FlashDeviceType", "Type");
        ciscoFlashDeviceObjects.put("Size", "Size");
        ciscoFlashDeviceObjects.put("NumberOfPartitions", "Partitions");
        ciscoFlashDeviceObjects.put("ChipCount", "Chip Count");
        ciscoFlashDeviceObjects.put("Description", "Description");
        ciscoFlashDeviceObjects.put("Removable", "Removable");

        // Populate the ciscoFlashPartitionObjects Hash
        this.ciscoFlashPartitionObjects = new Hashtable();
        ciscoFlashPartitionObjects.put("InstanceID", "Partition");
        ciscoFlashPartitionObjects.put("InstanceName", "Name");
        ciscoFlashPartitionObjects.put("Upgrade", "Upgrade");
        ciscoFlashPartitionObjects.put("NeedsErasure", "Needs Erasure");
        ciscoFlashPartitionObjects.put("PartitionStatus", "Status");
        ciscoFlashPartitionObjects.put("FileSystemSize", "Size");
        ciscoFlashPartitionObjects.put("AvailableSpace", "Available Space");
        ciscoFlashPartitionObjects.put("FileCount", "File Count");

        // Populate the ciscoFlashFileObjects Hash
        this.ciscoFlashFileObjects = new Hashtable();
        ciscoFlashFileObjects.put("InstanceID", "Index");
        ciscoFlashFileObjects.put("FileSize", "Size");
        ciscoFlashFileObjects.put("FileStatus", "Status");
        ciscoFlashFileObjects.put("Checksum", "Checksum");
        ciscoFlashFileObjects.put("InstanceName", "Name");

        // Populate the ciscoPhysicalMemoryObjects Hash
        this.ciscoPhysicalMemoryObjects = new Hashtable();
        ciscoPhysicalMemoryObjects.put("MemoryType", "Type");
        ciscoPhysicalMemoryObjects.put("Capacity", "Capacity");

        // Populate the ciscoNetworkElementObjects Hash
        this.ciscoNetworkElementObjects = new Hashtable();
        ciscoNetworkElementObjects.put("Description", "Description");
        ciscoNetworkElementObjects.put("PrimaryOwnerName", "Contact");
        ciscoNetworkElementObjects.put("InstanceName", "Device Name");
        ciscoNetworkElementObjects.put("PhysicalPosition", "Location");
        ciscoNetworkElementObjects.put("SysObjectId", "sysObjectID");
        ciscoNetworkElementObjects.put("OfficialHostName", "Hostname");
        ciscoNetworkElementObjects.put("NumberOfPorts", "Number of Slots");

        // Populate the ciscoLogicalModuleObjects Hash
        this.ciscoLogicalModuleObjects = new Hashtable();
        ciscoLogicalModuleObjects.put("InstanceID", "Module Index");
        ciscoLogicalModuleObjects.put("ModuleNumber", "Module Number");
        ciscoLogicalModuleObjects.put("ModuleType", "Type");
        ciscoLogicalModuleObjects.put("InstanceName", "Name");
        ciscoLogicalModuleObjects.put("EnabledStatus", "Enabled Status");
        ciscoLogicalModuleObjects.put("NumberOfPorts", "Number Of Ports");

        // Populate the ciscoPortObjects Hash
        this.ciscoPortObjects = new Hashtable();
        ciscoPortObjects.put("PortNumber", "Port Number");
        ciscoPortObjects.put("PortType", "Type");
        ciscoPortObjects.put("InstanceName", "Name");

        // Populate the ciscoIfEntryObjects Hash
        this.ciscoIfEntryObjects = new Hashtable();
        ciscoIfEntryObjects.put("InstanceID", "Index");
        ciscoIfEntryObjects.put("InstanceName", "Name");
        ciscoIfEntryObjects.put("ProtocolType", "Type");
        ciscoIfEntryObjects.put("Speed", "Speed");
        ciscoIfEntryObjects.put("RequestedStatus", "Admin Status");
        ciscoIfEntryObjects.put("OperationalStatus", "Operational Status");
        ciscoIfEntryObjects.put("Description", "Description");
        ciscoIfEntryObjects.put("PhysicalAddress", "Physical Address");
        ciscoIfEntryObjects.put("NetworkAddress", "Network Address");

        // Populate the ciscoMemoryPoolObjects Hash
        this.ciscoMemoryPoolObjects = new Hashtable();
        ciscoMemoryPoolObjects.put("PoolType", "Type");
        ciscoMemoryPoolObjects.put("DynamicPoolType", "Dynamic Pool");
        ciscoMemoryPoolObjects.put("AlternatePoolType", "Alternate Pool");
        ciscoMemoryPoolObjects.put("IsValid", "Validity");
        ciscoMemoryPoolObjects.put("Allocated", "Used");
        ciscoMemoryPoolObjects.put("Free", "Free");
        ciscoMemoryPoolObjects.put("LargestFree", "Largest Free Block");

        // Populate the ciscoOSElementObjects Hash
        this.ciscoOSElementObjects = new Hashtable();
        ciscoOSElementObjects.put("OSFamily", "OS Family");
        ciscoOSElementObjects.put("Version", "Version");
        ciscoOSElementObjects.put("Description", "Description");

        // Populate the ciscoIPProtoEndpointObjects Hash
        this.ciscoIPProtoEndpointObjects = new Hashtable();
        ciscoIPProtoEndpointObjects.put("Address", "Address");
        ciscoIPProtoEndpointObjects.put("SubnetMask", "Subnet Mask");
        ciscoIPProtoEndpointObjects.put("DefaultGateway", "Default Gateway");

        // Populate the ciscoPEHasIfEntryObjects Hash
        this.ciscoPEHasIfEntryObjects = new Hashtable();
        ciscoPEHasIfEntryObjects.put("Cisco_IPProtocolEndpoint", "Cisco IP Protocol Endpoint");
        ciscoPEHasIfEntryObjects.put("Cisco_IfEntry", "Cisco If Entry");

    }

    public void xml2CSV() {
        NodeList list = (((Document)document)).getElementsByTagName(RME_PLATFORM);
        for (int i = 0; i < list.getLength(); i++) {
            DEEsvDevice d = new DEEsvDevice();
            parseDevice(list.item(i), d);
            devices.addElement(d);
        }

    }

    public void printCSV() throws IOException {
        Enumeration e = devices.elements();
        while (e.hasMoreElements()) {
            DEEsvDevice d = (DEEsvDevice)e.nextElement();
            d.print(ps, this.separator);
        }
    }

    protected void parseDevice(Node n, DEEsvDevice device) {
        if (n.hasChildNodes()) {
            NodeList list = n.getChildNodes();
            if (list != null) {
                for (int i = 0; i < list.getLength(); i++) {
                    Node c = list.item(i);
                    if (c.getNodeName().equals(CISCO_NETWORK_ELEMENT)) {
                        parseCiscoNetworkElement(c, device);
                    }
                    else if (c.getNodeName().equals(CISCO_CHASSIS)) {
                        parseCiscoChassis(c, device);
                    }
                }
            }
        }
    }

    protected void parseCiscoNetworkElement(Node n, DEEsvDevice device) {
        Hashtable h = new Hashtable();
        DEEsvContainer netElement = device.getNetworkElement();

        if (n.hasChildNodes()) {
            NodeList list = n.getChildNodes();
            for (int i = 0; i < list.getLength(); i++) {
                Node c = list.item(i);
                if (ciscoNetworkElementObjects.containsKey(c.getNodeName())) {
                    String val = getElementText(c);
                    if (val != null) {
                        h.put(ciscoNetworkElementObjects.get(c.getNodeName()),
                              val);
                        if (!netElement.orderContains(
                                    ciscoNetworkElementObjects.get(c.getNodeName()))) {
                            netElement.addOrder(ciscoNetworkElementObjects.get(
                                                    c.getNodeName()));
                        }
                    }
                }
                else if (c.getNodeName().equals(ADD_INFO)) {
                    parseAdditionalInfo(c, h, netElement);
                }
                else if (c.getNodeName().equals(CISCO_LOGICAL_MODULE)) {
                    parseCiscoLogicalModule(c, device);
                }
                else if (c.getNodeName().equals(CISCO_PORT)) {
                    parseCiscoPort(c, device);
                }
                else if (c.getNodeName().equals(CISCO_MEMORY_POOL)) {
                    parseCiscoMemoryPool(c, device);
                }
                else if (c.getNodeName().equals(CISCO_IF_ENTRY)) {
                    parseCiscoIfEntry(c, device);
                }
                else if (c.getNodeName().equals(CISCO_IP_PROTO_ENDPOINT)) {
                    parseCiscoIPProtoEndpoint(c, device);
                }
                else if (c.getNodeName().equals(CISCO_PE_HAS_IF_ENTRY)) {
                    parseCiscoPEHasIfEntry(c, device);
                }
            }
            netElement.addData(h);
        }
    }

    protected void parseCiscoLogicalModule(Node n, DEEsvDevice device) {
        Hashtable h = new Hashtable();
        DEEsvContainer logicalModuleTable = device.getLogicalModuleTable();
        int osCnt = 1;

        if (n.hasChildNodes()) {
            NodeList list = n.getChildNodes();
            for (int i = 0; i < list.getLength(); i++) {
                Node c = list.item(i);
                if (ciscoLogicalModuleObjects.containsKey(c.getNodeName())) {
                    String val = getElementText(c);
                    if (val != null) {
                        h.put(ciscoLogicalModuleObjects.get(c.getNodeName()),
                              val);
                        if (!logicalModuleTable.orderContains(
                                    ciscoLogicalModuleObjects.get(c.getNodeName()))) {
                            logicalModuleTable.addOrder(
                                ciscoLogicalModuleObjects.get(c.getNodeName()));
                        }
                    }
                }
                else if (c.getNodeName().equals(CISCO_PORT)) {
                    parseCiscoPort(c, device);
                }
                else if (c.getNodeName().equals(CISCO_LOGICAL_MODULE)) {
                    parseCiscoLogicalModule(c, device);
                }
                else if (c.getNodeName().equals(CISCO_OS_ELEMENT)) {
                    parseCiscoOSElement(c, h, logicalModuleTable, osCnt++);
                }
                else if (c.getNodeName().equals(ADD_INFO)) {
                    parseAdditionalInfo(c, h, logicalModuleTable);
                }
            }
            logicalModuleTable.addData(h);
        }
    }

    protected void parseCiscoPort(Node n, DEEsvDevice device) {
        Hashtable h = new Hashtable();
        DEEsvContainer portTable = device.getPortTable();
        int ifIndexCnt = 1;

        if (n.hasChildNodes()) {
            NodeList list = n.getChildNodes();
            for (int i = 0; i < list.getLength(); i++) {
                Node c = list.item(i);
                if (ciscoPortObjects.containsKey(c.getNodeName())) {
                    String val = getElementText(c);
                    if (val != null) {
                        h.put(ciscoPortObjects.get(c.getNodeName()), val);
                        if (!portTable.orderContains(
                                    ciscoPortObjects.get(c.getNodeName()))) {
                            portTable.addOrder(ciscoPortObjects.get(
                                                   c.getNodeName()));
                        }
                    }
                }
                else if (c.getNodeName().equals(IF_INSTANCE_ID)) {
                    String val = getElementText(c);
                    if (val != null) {
                        h.put("Interface Index " + ifIndexCnt, val);
                        if (!portTable.orderContains("Interface Index " +
                                                     ifIndexCnt)) {
                            portTable.addOrder("Interface Index " +
                                               ifIndexCnt);
                        }
                        ifIndexCnt++;
                    }
                }
                else if (c.getNodeName().equals(ADD_INFO)) {
                    parseAdditionalInfo(c, h, portTable);
                }
            }
            portTable.addData(h);
        }
    }

    protected void parseCiscoIfEntry(Node n, DEEsvDevice device) {
        Hashtable h = new Hashtable();
        DEEsvContainer ifEntryTable = device.getIfEntryTable();

        if (n.hasChildNodes()) {
            NodeList list = n.getChildNodes();
            for (int i = 0; i < list.getLength(); i++) {
                Node c = list.item(i);
                if (ciscoIfEntryObjects.containsKey(c.getNodeName())) {
                    String val = getElementText(c);
                    if (val != null) {
                        h.put(ciscoIfEntryObjects.get(c.getNodeName()), val);
                        if (!ifEntryTable.orderContains(
                                    ciscoIfEntryObjects.get(c.getNodeName()))) {
                            ifEntryTable.addOrder(
                                ciscoIfEntryObjects.get(c.getNodeName()));
                        }
                    }
                }
                else if (c.getNodeName().equals(ADD_INFO)) {
                    parseAdditionalInfo(c, h, ifEntryTable);
                }
            }
            ifEntryTable.addData(h);
        }
    }

    protected void parseCiscoMemoryPool(Node n, DEEsvDevice device) {
        Hashtable h = new Hashtable();
        DEEsvContainer memoryPoolTable = device.getMemoryPoolTable();

        if (n.hasChildNodes()) {
            NodeList list = n.getChildNodes();
            for (int i = 0; i < list.getLength(); i++) {
                Node c = list.item(i);
                if (ciscoMemoryPoolObjects.containsKey(c.getNodeName())) {
                    String val = getElementText(c);
                    if (val != null) {
                        h.put(ciscoMemoryPoolObjects.get(c.getNodeName()), val);
                        if (!memoryPoolTable.orderContains(
                                    ciscoMemoryPoolObjects.get(c.getNodeName()))) {
                            memoryPoolTable.addOrder(
                                ciscoMemoryPoolObjects.get(c.getNodeName()));
                        }
                    }
                }
                else if (c.getNodeName().equals(ADD_INFO)) {
                    parseAdditionalInfo(c, h, memoryPoolTable);
                }
            }
            memoryPoolTable.addData(h);
        }
    }

    protected void parseCiscoIPProtoEndpoint(Node n, DEEsvDevice device) {
        Hashtable h = new Hashtable();
        DEEsvContainer ipProtoEndpointTable = device.getIPProtoEndpointTable();

        if (n.hasChildNodes()) {
            NodeList list = n.getChildNodes();
            for (int i = 0; i < list.getLength(); i++) {
                Node c = list.item(i);
                if (ciscoIPProtoEndpointObjects.containsKey(c.getNodeName())) {
                    String val = getElementText(c);
                    if (val != null) {
                        h.put(ciscoIPProtoEndpointObjects.get(
                                  c.getNodeName()), val);
                        if (!ipProtoEndpointTable.orderContains(
                                    ciscoIPProtoEndpointObjects.get(c.getNodeName()))) {
                            ipProtoEndpointTable.addOrder(
                                ciscoIPProtoEndpointObjects.get(
                                    c.getNodeName()));
                        }
                    }
                }
                else if (c.getNodeName().equals(ADD_INFO)) {
                    parseAdditionalInfo(c, h, ipProtoEndpointTable);
                }
            }
            ipProtoEndpointTable.addData(h);
        }
    }

    protected void parseCiscoPEHasIfEntry(Node n, DEEsvDevice device) {
        Hashtable h = new Hashtable();
        DEEsvContainer peHasIfEntryTable = device.getPEHasIfEntryTable();

        if (n.hasChildNodes()) {
            NodeList list = n.getChildNodes();
            for (int i = 0; i < list.getLength(); i++) {
                Node c = list.item(i);
                if (ciscoPEHasIfEntryObjects.containsKey(c.getNodeName())) {
                    String val = getElementText(c);
                    if (val != null) {
                        h.put(ciscoPEHasIfEntryObjects.get(
                                  c.getNodeName()), val);
                        if (!peHasIfEntryTable.orderContains(
                                    ciscoPEHasIfEntryObjects.get(c.getNodeName()))) {
                            peHasIfEntryTable.addOrder(
                                ciscoPEHasIfEntryObjects.get(
                                    c.getNodeName()));
                        }
                    }
                }
            }
            peHasIfEntryTable.addData(h);
        }
    }

    protected void parseCiscoChassis(Node n, DEEsvDevice device) {
        Hashtable h = new Hashtable();
        DEEsvContainer chassis = device.getChassis();
        int backplaneCnt = 1;

        if (n.hasChildNodes()) {
            NodeList list = n.getChildNodes();
            if (list != null) {
                for (int i = 0; i < list.getLength(); i++) {
                    Node c = list.item(i);
                    if (chassisObjects.containsKey(c.getNodeName())) {
                        String val = getElementText(c);
                        if (val != null) {
                            h.put(chassisObjects.get(c.getNodeName()),
                                  val);
                            if (!chassis.orderContains(c.getNodeName())) {
                                chassis.addOrder(
                                    chassisObjects.get(c.getNodeName()));
                            }
                        }
                    }
                    else if (c.getNodeName().equals(ADD_INFO)) {
                        parseAdditionalInfo(c, h, chassis);
                    }
                    else if (c.getNodeName().equals(CISCO_BACKPLANE)) {
                        parseBackplane(c, h, chassis, backplaneCnt++);
                    }
                    else if (c.getNodeName().equals(CISCO_CARD)) {
                        parseCiscoCard(c, device); // Cards get their own hash
                    }

                }
                chassis.addData(h);
            }
        }
    }

    protected void parseCiscoCard(Node n, DEEsvDevice device) {
        Hashtable h = new Hashtable();
        DEEsvContainer cardTable = device.getCardTable();
        int softwareCnt = 1;
        int commCnt = 1;

        if (n.hasChildNodes()) {
            NodeList list = n.getChildNodes();
            for (int i = 0; i < list.getLength(); i++) {
                Node c = list.item(i);
                if (cardObjects.containsKey(c.getNodeName())) {
                    String val = getElementText(c);
                    if (val != null) {
                        h.put(cardObjects.get(c.getNodeName()),
                              val);
                        if (!cardTable.orderContains(
                                    cardObjects.get(c.getNodeName()))) {
                            cardTable.addOrder(
                                cardObjects.get(c.getNodeName()));
                        }
                    }
                }
                else if (c.getNodeName().equals(SOFTWARE_IDENTITY)) {
                    parseSoftwareIdentity(c, h, cardTable, softwareCnt++);
                }
                else if (c.getNodeName().equals(CISCO_COMM_CONNECTOR)) {
                    parseCiscoCommConnector(c, h, cardTable, commCnt++);
                }
                else if (c.getNodeName().equals(CISCO_FLASH_DEVICE)) {
                    parseCiscoFlashDevice(c, device);
                }
                else if (c.getNodeName().equals(CISCO_PHYSICAL_MEMORY)) {
                    parseCiscoPhysicalMemory(c, device);
                }
                else if (c.getNodeName().equals(CISCO_CARD)) {
                    // XXX This needs to be handled with recurrsion probably.
                    System.err.println("XXX: Unimplemented recursive " +
                                       CISCO_CARD);
                }
                else if (c.getNodeName().equals(ADD_INFO)) {
                    parseAdditionalInfo(c, h, cardTable);
                }

            }
            cardTable.addData(h);
        }
    }

    protected void parseCiscoPhysicalMemory(Node n, DEEsvDevice device) {
        Hashtable h = new Hashtable();
        DEEsvContainer physMemTable = device.getPhysicalMemoryTable();

        if (n.hasChildNodes()) {
            NodeList list = n.getChildNodes();
            for (int i = 0; i < list.getLength(); i++) {
                Node c = list.item(i);
                if (ciscoPhysicalMemoryObjects.containsKey(c.getNodeName())) {
                    String val = getElementText(c);
                    if (val != null) {
                        h.put(ciscoPhysicalMemoryObjects.get(c.getNodeName()),
                              val);
                        if (!physMemTable.orderContains(
                                    ciscoPhysicalMemoryObjects.get(
                                        c.getNodeName()))) {
                            physMemTable.addOrder(
                                ciscoPhysicalMemoryObjects.get(
                                    c.getNodeName()));
                        }
                    }
                }
            }
            physMemTable.addData(h);
        }
    }

    protected void parseCiscoFlashDevice(Node n, DEEsvDevice device) {
        Hashtable h = new Hashtable();
        DEEsvContainer flashTable = device.getFlashDeviceTable();

        if (n.hasChildNodes()) {
            NodeList list = n.getChildNodes();
            for (int i = 0; i < list.getLength(); i++) {
                Node c = list.item(i);
                if (ciscoFlashDeviceObjects.containsKey(c.getNodeName())) {
                    String val = getElementText(c);
                    if (val != null) {
                        h.put(ciscoFlashDeviceObjects.get(c.getNodeName()),
                              val);
                        if (!flashTable.orderContains(
                                    ciscoFlashDeviceObjects.get(c.getNodeName()))) {
                            flashTable.addOrder(ciscoFlashDeviceObjects.get(
                                                    c.getNodeName()));
                        }
                    }
                }
                else if (c.getNodeName().equals(CISCO_FLASH_PARTITION)) {
                    parseCiscoFlashPartition(c, device);
                }
                else if (c.getNodeName().equals(ADD_INFO)) {
                    parseAdditionalInfo(c, h, flashTable);
                }
            }
            flashTable.addData(h);
        }
    }

    protected void parseCiscoFlashPartition(Node n, DEEsvDevice device) {
        Hashtable h = new Hashtable();
        DEEsvContainer partitionTable = device.getFlashPartitionTable();

        if (n.hasChildNodes()) {
            NodeList list = n.getChildNodes();
            for (int i = 0; i < list.getLength(); i++) {
                Node c = list.item(i);
                if (ciscoFlashPartitionObjects.containsKey(c.getNodeName())) {
                    String val = getElementText(c);
                    if (val != null) {
                        h.put(ciscoFlashPartitionObjects.get(
                                  c.getNodeName()), val);
                        if (!partitionTable.orderContains(c.getNodeName())) {
                            partitionTable.addOrder(
                                ciscoFlashPartitionObjects.get(
                                    c.getNodeName()));
                        }
                    }
                }
                else if (c.getNodeName().equals(ADD_INFO)) {
                    parseAdditionalInfo(c, h, partitionTable);
                }
                else if (c.getNodeName().equals(CISCO_FLASH_FILE)) {
                    parseCiscoFlashFile(c, device);
                }
            }
            partitionTable.addData(h);
        }
    }

    protected void parseCiscoFlashFile(Node n, DEEsvDevice device) {
        Hashtable h = new Hashtable();
        DEEsvContainer fileTable = device.getFlashFileTable();

        if (n.hasChildNodes()) {
            NodeList list = n.getChildNodes();
            for (int i = 0; i < list.getLength(); i++) {
                Node c = list.item(i);
                if (ciscoFlashFileObjects.containsKey(c.getNodeName())) {
                    String val = getElementText(c);
                    if (val != null) {
                        h.put(ciscoFlashFileObjects.get(c.getNodeName()),
                              val);
                        if (!fileTable.orderContains(ciscoFlashFileObjects.get(
                                                         c.getNodeName()))) {
                            fileTable.addOrder(ciscoFlashFileObjects.get(
                                                   c.getNodeName()));
                        }
                    }
                }
                else if (c.getNodeName().equals(ADD_INFO)) {
                    parseAdditionalInfo(c, h, fileTable);
                }
            }
            fileTable.addData(h);
        }
    }

    protected void parseBackplane(Node n, Hashtable h, DEEsvContainer dc,
                                  int cnt) {

        if (n.hasChildNodes()) {
            NodeList list = n.getChildNodes();
            for (int i = 0; i < list.getLength(); i++) {
                Node c = list.item(i);
                if (backplaneObjects.containsKey(c.getNodeName())) {
                    String val = getElementText(c);
                    if (val != null) {
                        h.put(backplaneObjects.get(c.getNodeName()) +
                              " " + cnt, val);
                        if (!dc.orderContains(backplaneObjects.get(
                                                  c.getNodeName()) + " " + cnt)) {
                            dc.addOrder(backplaneObjects.get(
                                            c.getNodeName()) + " " + cnt);
                        }
                    }
                }
                else if (c.getNodeName().equals(ADD_INFO)) {
                    parseAdditionalInfo(c, h, dc);
                }
            }
        }
    }

    protected void parseCiscoOSElement(Node n, Hashtable h, DEEsvContainer dc,
                                       int cnt) {

        if (n.hasChildNodes()) {
            NodeList list = n.getChildNodes();
            for (int i = 0; i < list.getLength(); i++) {
                Node c = list.item(i);
                if (ciscoOSElementObjects.containsKey(c.getNodeName())) {
                    String val = getElementText(c);
                    if (val != null) {
                        h.put(ciscoOSElementObjects.get(c.getNodeName()) +
                              " " + cnt, val);
                        if (!dc.orderContains(ciscoOSElementObjects.get(
                                                  c.getNodeName()) + " " + cnt)) {
                            dc.addOrder(ciscoOSElementObjects.get(
                                            c.getNodeName()) + " " + cnt);
                        }
                    }
                }
                else if (c.getNodeName().equals(ADD_INFO)) {
                    parseAdditionalInfo(c, h, dc);
                }
            }
        }
    }

    protected void parseSoftwareIdentity(Node n, Hashtable h, DEEsvContainer dc,
                                         int cnt) {

        if (n.hasChildNodes()) {
            NodeList list = n.getChildNodes();
            for (int i = 0; i < list.getLength(); i++) {
                Node c = list.item(i);
                if (softwareIdentityObjects.containsKey(
                            c.getNodeName())) {
                    String val = getElementText(c);
                    if (val != null) {
                        h.put(softwareIdentityObjects.get(c.getNodeName()) +
                              " " + cnt, val);
                        if (!dc.orderContains(softwareIdentityObjects.get(
                                                  c.getNodeName()) + " " + cnt)) {
                            dc.addOrder(
                                softwareIdentityObjects.get(c.getNodeName()) +
                                " " + cnt);
                        }
                    }
                }
            }
        }
    }


    protected void parseCiscoCommConnector(Node n, Hashtable h,
                                           DEEsvContainer dc, int cnt) {

        if (n.hasChildNodes()) {
            NodeList list = n.getChildNodes();
            for (int i = 0; i < list.getLength(); i++) {
                Node c = list.item(i);
                if (ciscoCommunicationConnectorObjects.containsKey(
                            c.getNodeName())) {
                    String val = getElementText(c);
                    if (val != null) {
                        h.put(ciscoCommunicationConnectorObjects.get(
                                  c.getNodeName()) + " " + cnt, val);
                        if (!dc.orderContains(
                                    ciscoCommunicationConnectorObjects.get(
                                        c.getNodeName()) + " " + cnt)) {
                            dc.addOrder(
                                ciscoCommunicationConnectorObjects.get(
                                    c.getNodeName()) + " " + cnt);
                        }
                    }
                }
            }
        }
    }

    protected void parseAdditionalInfo(Node n, Hashtable h, DEEsvContainer dc) {
        if (n.hasChildNodes()) {
            NodeList list = n.getChildNodes();
            for (int i = 0; i < list.getLength(); i++) {
                Node c = list.item(i);
                NamedNodeMap map = c.getAttributes();
                if (map != null) {
                    Node name = map.getNamedItem("name");
                    Node value = map.getNamedItem("value");
                    if (name != null && value != null &&
                            name.getNodeValue() != null &&
                            value.getNodeValue() != null) {
                        h.put(name.getNodeValue(), value.getNodeValue());
                        if (!dc.orderContains(name.getNodeValue())) {
                            dc.addOrder(name.getNodeValue());
                        }
                    }
                }

            }
        }
    }

    protected String getElementText(Node n) {
        StringBuffer sb = new StringBuffer();
        if (!n.hasChildNodes()) return null;
        NodeList list = n.getChildNodes();
        for (int i = 0; i < list.getLength(); i++) {
            Node c = list.item(i);
            if (c instanceof Text) {
                if (!c.getNodeValue().equals("")) {
                    sb.append(c.getNodeValue());
                }
            }
        }

        if (sb.toString().equals("")) return null;
        return sb.toString();
    }


}
