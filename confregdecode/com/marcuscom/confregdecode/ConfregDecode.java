/*-
 * Copyright (c) 1998-2001 Joe Clarke <marcus@marcuscom.com>
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

package com.marcuscom.confregdecode;

import java.awt.*;
import java.awt.event.*;
import java.applet.*;
import java.util.*;

public class ConfregDecode extends Applet implements ActionListener {
    int parsedHex;
    Panel leftPanel, rightPanel;
    TextField registerInputField;
    TextArea notesArea;
    Label confreg, footnote;
    CheckboxGroup bootIntoGroup;
    PropChoice baudRatesChoice, bootFilesChoice;
    CheckboxGroup broadcastGroup;
    PropCheckbox[] bootModes, options,broadcasts;
    RouterChoice routerType;
    Label notesLabel;

    public static final Font DEFAULT_FONT = new Font("SansSerif",Font.PLAIN,12);
    public static final Font BIG_FONT = new Font("SansSerif",Font.BOLD,12);

    static Frame f;

    static final String HEX_PREFIX = "0x";
    static final int BAUD_1200 = 0x1000;
    static final int BAUD_2400 = 0x1800;
    static final int BAUD_4800 = 0x0800;
    static final int BAUD_9600 = 0x0000;
    static final int BAUD_19200 = 0x0020;
    static final int BAUD_38400 = 0x0820;
    static final int BAUD_57600 = 0x1020;
    static final int BAUD_115200 = 0x1820;

    static final int BOOT_ROM = 0x0000;
    static final int BOOT_BOOT = 0x0001;
    static final int BOOT_FLASH = 0x0002;
    static final int BOOT_MASK = 0x0003;

    static final int CISCO_2 = 0x0002;
    static final int CISCO_3 = 0x0003;
    static final int CISCO_4 = 0x0004;
    static final int CISCO_5 = 0x0005;
    static final int CISCO_6 = 0x0006;
    static final int CISCO_7 = 0x0007;
    static final int CISCO_10 = 0x0008;
    static final int CISCO_11 = 0x0009;
    static final int CISCO_12 = 0x000a;
    static final int CISCO_13 = 0x000b;
    static final int CISCO_14 = 0x000c;
    static final int CISCO_15 = 0x000d;
    static final int CISCO_16 = 0x000e;
    static final int CISCO_17 = 0x000f;
    static final int BOOT_FILE_MASK = 0x000F;

    static final int IGNORE_NVRAM = 0x0040;

    static final int OEM_BIT = 0x0080;

    static final int IGNORE_BREAK = 0x0100;

    static final int BCAST_ALL_ONES = 0x0000;
    static final int BCAST_ALL_ZEROS = 0x0400;
    static final int NET_BCAST_ZEROS = 0x4400;
    static final int NET_BCAST_ONES = 0x4000;
    static final int BCAST_MASK = 0x4400;

    static final int NET_BOOT = 0x2000;

    static final int DIAG_MODE = 0x8000;
    static final int OPTIONS_MASK = 0xA1C0;


    public ConfregDecode() {

        this.setFont(DEFAULT_FONT);

        System.out.println("cisco Systems IOS Configuration Register Decoder\n$Id$ \nby Joe Clarke");

        bootIntoGroup = new CheckboxGroup();
        bootModes = new PropCheckbox[4];
        bootModes[0] = new PropCheckbox("ROM (ROMMON)", bootIntoGroup, false, BOOT_ROM);
        bootModes[1] = new PropCheckbox("Boot strap", bootIntoGroup, false, BOOT_BOOT);
        bootModes[2] = new PropCheckbox("Flash *", bootIntoGroup, false, BOOT_FLASH);
        bootModes[3] = new PropCheckbox("NetBoot", bootIntoGroup, false, 0x0000);

        options = new PropCheckbox[5];
        options[0] = new PropCheckbox("Ignore NVRAM", IGNORE_NVRAM);
        options[1] = new PropCheckbox("Disable boot messages", OEM_BIT);
        options[2] = new PropCheckbox("Ignore break *", IGNORE_BREAK);
        options[3] = new PropCheckbox("Boot into ROM if initial boot fails *", NET_BOOT);
        options[4] = new PropCheckbox("Diagnostic mode", DIAG_MODE);

        baudRatesChoice = new PropChoice();
        baudRatesChoice.addItem("", -1);
        baudRatesChoice.addItem("1200", BAUD_1200);
        baudRatesChoice.addItem("2400", BAUD_2400);
        baudRatesChoice.addItem("4800", BAUD_4800);
        baudRatesChoice.addItem("9600 *", BAUD_9600);
        baudRatesChoice.addItem("19200", BAUD_19200);
        baudRatesChoice.addItem("38400", BAUD_38400);
        baudRatesChoice.addItem("57600", BAUD_57600);
        baudRatesChoice.addItem("115200", BAUD_115200);

        broadcastGroup = new CheckboxGroup();
        broadcasts = new PropCheckbox[4];
        broadcasts[0] = new PropCheckbox("Net all ones, bcast all ones *", broadcastGroup, false, BCAST_ALL_ONES);
        broadcasts[1] = new PropCheckbox("Net all zeros, bcast all zeros", broadcastGroup, false, BCAST_ALL_ZEROS);
        broadcasts[2] = new PropCheckbox("Net address, bcast all zeros", broadcastGroup, false, NET_BCAST_ZEROS);
        broadcasts[3] = new PropCheckbox("Net address, bcast all ones", broadcastGroup, false, NET_BCAST_ONES);

        bootFilesChoice = new PropChoice();
        bootFilesChoice.addItem("", -1);
        bootFilesChoice.addItem("cisco2-<router type>", CISCO_2);
        bootFilesChoice.addItem("cisco3-<router type>", CISCO_3);
        bootFilesChoice.addItem("cisco4-<router type>", CISCO_4);
        bootFilesChoice.addItem("cisco5-<router type>", CISCO_5);
        bootFilesChoice.addItem("cisco6-<router type>", CISCO_6);
        bootFilesChoice.addItem("cisco7-<router type>", CISCO_7);
        bootFilesChoice.addItem("cisco10-<router type>", CISCO_10);
        bootFilesChoice.addItem("cisco11-<router type>", CISCO_11);
        bootFilesChoice.addItem("cisco12-<router type>", CISCO_12);
        bootFilesChoice.addItem("cisco13-<router type>", CISCO_13);
        bootFilesChoice.addItem("cisco14-<router type>", CISCO_14);
        bootFilesChoice.addItem("cisco15-<router type>", CISCO_15);
        bootFilesChoice.addItem("cisco16-<router type>", CISCO_16);
        bootFilesChoice.addItem("cisco17-<router type>", CISCO_17);

        routerType = new RouterChoice();
        routerType.addItem("1000 Series", true);
        routerType.addItem("1600 Series", true);
        routerType.addItem("1700 Series", true);
        routerType.addItem("2000/3000 Series", true);
        routerType.addItem("2500 Series", true);
        routerType.addItem("2600 Series", false);
        routerType.addItem("AccessPro Series", true);
        routerType.addItem("3600 Series", false);
        routerType.addItem("MC3810", false);
        routerType.addItem("4000 Series", true);
        routerType.addItem("7000 Family", true);
        routerType.addItem("GSR Family", true);
        routerType.addItem("7200 Series", true);
        routerType.addItem("AGS+/AGS/MGS/CGS", true);
        routerType.addItem("AS5xxx", true);
        routerType.addItem("ASM-CS", true);

        this.setLayout(new BorderLayout(10, 10));

        registerInputField = new TextField(6);
        notesArea = new TextArea(6,42);
        notesArea.setEditable(false);

        leftPanel = new Panel();
        leftPanel.setLayout(new ColumnLayout(0, 1, 1, ColumnLayout.LEFT));
        this.add(leftPanel, "West");

        Label instructLabel = new Label("Config-reg value: ");
        instructLabel.setFont(BIG_FONT);
        registerInputField.setFont(BIG_FONT);
        leftPanel.add(instructLabel);
        leftPanel.add(registerInputField);
        registerInputField.addActionListener(new ActionListener() {
                                                 public void actionPerformed(ActionEvent e) {
                                                     getNotes(routerType.getSelectedItem());
                                                     parseRegister(((TextField)e.getSource()).getText());
                                                 }
                                             });

        leftPanel.add(new Label("Select router type:"));
        leftPanel.add(routerType);
        routerType.addItemListener(new ItemListener() {
                                       public void itemStateChanged(ItemEvent e) {
                                           parseRegister(registerInputField.getText());
                                           getNotes(routerType.getSelectedItem());
                                       }
                                   });
        leftPanel.add(new Label("Will boot into:"));
        for (int i = 0; i < bootModes.length; i++) {
            leftPanel.add(bootModes[i]);
        }
        ItemListener bootmodes_listener = new ItemListener() {
                                              public void itemStateChanged(ItemEvent e) {
                                                  bootFilesChoice.select("");
                                                  getNotes(routerType.getSelectedItem());
                                                  calculateRegister();
                                              }
                                          };
        ItemListener default_item_listener = new ItemListener() {
                                                 public void itemStateChanged(ItemEvent e) {
                                                     getNotes(routerType.getSelectedItem());
                                                     calculateRegister();
                                                 }
                                             };

        for (int i = 0; i < bootModes.length; i++) {
            bootModes[i].addItemListener(bootmodes_listener);
        }
        leftPanel.add(new Label("Options:"));
        for (int i = 0; i < options.length; i++) {
            options[i].addItemListener(default_item_listener);
            leftPanel.add(options[i]);
        }
        rightPanel = new Panel();
        rightPanel.setLayout(new ColumnLayout(0, 1, 1, ColumnLayout.LEFT));
        this.add(rightPanel, "Center");

        notesLabel = new Label("Series-specific Router Notes: ");

        rightPanel.add(notesLabel);
        rightPanel.add(notesArea);
        rightPanel.add(new Label("Broadcast Parameters:"));
        for (int i = 0; i < broadcasts.length; i++) {
            broadcasts[i].addItemListener(default_item_listener);
            rightPanel.add(broadcasts[i]);
        }
        rightPanel.add(new Label("NetBoot Using File:"));
        rightPanel.add(bootFilesChoice);
        bootFilesChoice.addItemListener(default_item_listener);

        rightPanel.add(new Label("Console Baud Rate:"));
        rightPanel.add(baudRatesChoice);
        baudRatesChoice.addItemListener(default_item_listener);
        this.validate();
        this.transferFocus();
        registerInputField.requestFocus();
    }

    public void parseRegister(String configReg) {
        configReg = configReg.toLowerCase();
        if (configReg.startsWith(HEX_PREFIX)) {
            configReg = configReg.substring(HEX_PREFIX.length());
        }
        try {
            parsedHex = Integer.parseInt(configReg, 16);
        }
        catch (NumberFormatException nfe1) {
            notesArea.setText("The number you entered is not a valid config-reg value.");
            return;
        }
        parseBaud();
        parseOptions();
        parseBootMode();
        parseBootFile();
        parseBroadcast();
    }

    public void parseBaud() {
        int baudMask, maskedBits;
        if (!routerType.isOld(routerType.getSelectedItem())) { // new router series
            baudMask = 0x1820;
        }
        else {
            baudMask = 0x1800;
        }

        maskedBits = parsedHex & baudMask;
        switch(maskedBits) {
        case BAUD_1200:
            baudRatesChoice.select(1);
            break;
        case BAUD_2400:
            baudRatesChoice.select(2);
            break;
        case BAUD_4800:
            baudRatesChoice.select(3);
            break;
        case BAUD_9600:
            baudRatesChoice.select(4);
            break;
        case BAUD_19200:
            baudRatesChoice.select(5);
            break;
        case BAUD_38400:
            baudRatesChoice.select(6);
            break;
        case BAUD_57600:
            baudRatesChoice.select(7);
            break;
        case BAUD_115200:
            baudRatesChoice.select(8);
            break;
        default:
            notesArea.setText("Error in baud bits.");
        }
    }
    public void parseBootMode() {
        // bootModes mask = 0x0003
        int maskedBits;

        bootIntoGroup.setSelectedCheckbox(null);

        maskedBits = BOOT_MASK & parsedHex;

        switch(maskedBits) {
        case BOOT_ROM:
            bootModes[0].setState(true);
            bootFilesChoice.select("");
            break;
        case BOOT_BOOT:
            if (routerType.getSelectedItem().equals("2600 Series") ||
                    routerType.getSelectedItem().equals("3600 Series") || routerType.getSelectedItem().equals("MC3810"))
            {
                bootModes[2].setState(true);
            }
            else {
                bootModes[1].setState(true);
            }
            bootFilesChoice.select("");
            break;
        case BOOT_FLASH:
            bootModes[2].setState(true);
            bootFilesChoice.select(1);
            break;
        default:
        }
    }

    public void parseOptions() {

        // Reset the options every recalculation
        for (int i = 0; i < options.length; i++) {
            options[i].setState(false);
        }

        if ((parsedHex & IGNORE_NVRAM) == IGNORE_NVRAM) options[0].setState(true);
        if ((parsedHex & OEM_BIT) == OEM_BIT) options[1].setState(true);
        if ((parsedHex & IGNORE_BREAK) == IGNORE_BREAK) options[2].setState(true);
        if ((parsedHex & NET_BOOT) == NET_BOOT) options[3].setState(true);
        if ((parsedHex & DIAG_MODE) == DIAG_MODE) options[4].setState(true);
    }

    public void parseBootFile() {
        int maskedBits;

        bootFilesChoice.select("");

        maskedBits = parsedHex & BOOT_FILE_MASK;
        switch(maskedBits) {
        case CISCO_2:
            bootFilesChoice.select(1);
            bootModes[2].setState(true);
            break;
        case CISCO_3:
            bootFilesChoice.select(2);
            bootModes[3].setState(true); // NetBoot
            break;
        case CISCO_4:
            bootFilesChoice.select(3);
            bootModes[3].setState(true); // NetBoot
            break;
        case CISCO_5:
            bootFilesChoice.select(4);
            bootModes[3].setState(true); // NetBoot
            break;
        case CISCO_6:
            bootModes[3].setState(true); // NetBoot
            bootFilesChoice.select(5);
            break;
        case CISCO_7:
            bootFilesChoice.select(6);
            bootModes[3].setState(true); // NetBoot
            break;
        case CISCO_10:
            bootModes[3].setState(true); // NetBoot
            bootFilesChoice.select(7);
            break;
        case CISCO_11:
            bootModes[3].setState(true); // NetBoot
            bootFilesChoice.select(8);
            break;
        case CISCO_12:
            bootModes[3].setState(true); // NetBoot
            bootFilesChoice.select(9);
            break;
        case CISCO_13:
            bootModes[3].setState(true); // NetBoot
            bootFilesChoice.select(10);
            break;
        case CISCO_14:
            bootModes[3].setState(true); // NetBoot
            bootFilesChoice.select(11);
            break;
        case CISCO_15:
            bootModes[3].setState(true); // NetBoot
            bootFilesChoice.select(12);
            break;
        case CISCO_16:
            bootModes[3].setState(true); // NetBoot
            bootFilesChoice.select(13);
            break;
        case CISCO_17:
            bootModes[3].setState(true); // NetBoot
            bootFilesChoice.select(14);
            break;
        default:
        }
    }

    public void parseBroadcast() {
        int maskedBits;

        maskedBits = parsedHex & BCAST_MASK;
        switch(maskedBits) {
        case BCAST_ALL_ONES:
            broadcasts[0].setState(true);
            break;
        case BCAST_ALL_ZEROS:
            broadcasts[1].setState(true);
            break;
        case NET_BCAST_ZEROS:
            broadcasts[2].setState(true);
            break;
        case NET_BCAST_ONES:
            broadcasts[3].setState(true);
            break;
        default:
            notesArea.setText("Unknown broadcast " + maskedBits + ".\n");
        }
    }

    public void getNotes(String router) {
        notesArea.setText(""); // clear notes area

        notesLabel.setText("Notes for " + router + " routers: ");

        notesArea.append("Note: IOS reads the config-register in\n   littleendian byte order, LSB first (i.e.\n   0x21022 becomes 0x1022 or a 1200 baud\n   console).\n\n");

        if (router.equals("1700 Series")) {
            notesArea.append("On most router families, setting the register to 0x3922 will wrap it\nto 2400 baud.  This does not happen on the 1700 series.  Instead,\nIOS will not allow you to set the register\"higher\" than 0x2102.\n\n");
        }
        if (router.equals("GSR Family") || router.equals("7000 Family") || router.equals("7500 Series") || router.equals("7200 Series") || router.equals("4000 Series") || router.equals("2600 Series") || router.equals("3600 Series") || router.equals("MC3810") || router.equals("AS5xxx") || router.equals("1000 Series") || router.equals("1600 Series") || router.equals("1700 Series")) {
            notesArea.append("Command to change config-reg in ROMMON:\n  confreg <register value>\n");
        }
        else {
            notesArea.append("Command to change config-reg in ROM mode:\n  o/r <register value>\n");
        }
        if (router.equals("2600 Series") || router.equals("3600 Series")) {
            notesArea.append("\nCan xmodem a file into flash from ROMMON:\n  xmodem -c <filename>\n");
        }
        if (router.equals("1600 Series")) {
            notesArea.append("\nCan xmodem a file into flash from ROMMON:\n xmodem -cfs115200 <filename>\n");
            notesArea.append("This sets the console baud to 115200, \n erases the flash, downloads the image,\n  and performs CRC-16 error checking.\n");
            notesArea.append("\nSetting the console baud to 115200 is only supported DURING\n  the xmodem.  Afterward you must change\n  the baud rate back to 9600 or less.\n");
        }

        if (router.equals("2600 Series") ||  router.equals("3600 Series")) {
            notesArea.append("(*Hint* Set console baud to 115200 before doing an xmodem)\n\n");
            notesArea.append("\nROMMON Security requires:\n - No boot to ROMMON\n - Break disabled\n - Can't ignore NVRAM\n - No diagnostic mode\n");
            notesArea.append("\nReset console baud rate to 9600:\n - 3620/2600 shunt pins 1-2 on the J3 jumper (DUART_RST)\n - 3640 shunt pins 1-2 on J3 jumper (BAUD_RST)\n");
        }

        if (router.equals("2600 Series")) {
            notesArea.append("\nCan tftp a file into flash from ROMMON:\n  tftpdnld\n\n");
        }
        notesArea.setCaretPosition(0); // Set the pointer position back to the start of the text (new to Java 1.1)

    }

    public void calculateRegister() {
        int newRegister, bootIntoValue, baudValue, bcastValue, bootFileValue;

        if (bootFilesChoice.getSelectedItem().equals("")) bootFileValue = 0;
        else {
            if (bootFilesChoice.getSelectedIndex() == 1) {
                bootModes[2].setState(true);
            }
            else {
                bootModes[3].setState(true);
            }
            bootFileValue = bootFilesChoice.getSelectedValue();
        }
        if (baudRatesChoice.getSelectedItem().equals("")) baudValue = 0;
        else baudValue = baudRatesChoice.getSelectedValue();

        if (bootIntoGroup.getSelectedCheckbox() == null) bootIntoValue = 0;
        else {
            bootIntoValue = ((PropCheckbox)bootIntoGroup.getSelectedCheckbox()).getPropValue();
            if (bootModes[2].getState() == true) {
                bootFilesChoice.select(1);
            }
        }

        if (broadcastGroup.getSelectedCheckbox() == null) bcastValue = 0;
        else bcastValue = ((PropCheckbox)broadcastGroup.getSelectedCheckbox()).getPropValue();


        /*System.out.println(baudValue);
        System.out.println(bootIntoValue);
        System.out.println(bcastValue);
        System.out.println(bootFileValue);*/
        newRegister = baudValue | bootIntoValue | bcastValue | bootFileValue;
        for(int i = 0; i < options.length; i++) {
            if (options[i].getState()) newRegister = newRegister | options[i].getPropValue();
            //System.out.println("options " + options[i].getLabel() + " is true, value " + options[i].getPropValue());
        }

        //System.out.println("Printing register.");
        //System.out.println(newRegister);
        if (routerType.isOld(routerType.getSelectedItem()) && (newRegister & 0x0020) == 0x0020) {
            notesArea.setText("This router only supports console speeds up to 9600 baud.");
        }
        else {
            registerInputField.setText(HEX_PREFIX + Integer.toString(newRegister, 16));
        }
    }

    public String getAppletInfo() {
        return "cisco Systems IOS Configuration Register Decoder\n$Id$ \nby Joe Clarke (jclarke)";
    }

    public static void main(String[] argv) {
        f = new Frame("cisco Systems Config-Register Decoder");
        ConfregDecode cd = new ConfregDecode();
        f.setSize(575,450);
        f.addWindowListener(new WindowAdapter() {
                                public void windowClosing(WindowEvent e) { System.exit(0); }
                            });
        f.setFont(DEFAULT_FONT);
        MenuBar menubar = new MenuBar();
        f.setMenuBar(menubar);
        Menu file = new Menu("File");
        menubar.add(file);
        MenuItem quit = new MenuItem("Quit", new MenuShortcut(KeyEvent.VK_Q));
        quit.setActionCommand("quit");
        quit.addActionListener(cd);
        file.add(quit);
        Menu help = new Menu("Help");
        menubar.add(help);
        menubar.setHelpMenu(help);
        MenuItem about = new MenuItem("About");
        about.setActionCommand("about");
        about.addActionListener(cd);
        help.add(about);
        f.setLayout(new BorderLayout(10, 10));
        f.add(cd);
        f.show();
    }

    public void actionPerformed(ActionEvent e) {
        String command = e.getActionCommand();
        if (command.equals("quit")) {
            System.exit(0);
        }
        else if (command.equals("about")) {
            InfoDialog d = new InfoDialog(f, "About", "cisco Systems IOS Configuration Register Decoder\n$Id$\n");
            d.show();
        }
    }


}

class PropCheckbox extends Checkbox {
    protected int value;

    PropCheckbox(String label, CheckboxGroup group, boolean state, int value) {
        super(label,group,state);
        this.value = value;
    }

    PropCheckbox(String label, int value) {
        super(label);
        this.value = value;
    }

    public synchronized int getPropValue() {
        return this.value;
    }

}

class PropChoice extends Choice {
    protected Hashtable values;

    PropChoice() {
        super();
        values = new Hashtable();
    }

    public synchronized void addItem(String item, int value) {
        super.addItem(item);
        this.values.put(item, new Integer(value));
    }

    public synchronized int getSelectedValue() {
        return(((Integer)values.get(this.getSelectedItem())).intValue());
    }
}

class RouterChoice extends Choice {
    protected Hashtable routerAge;

    RouterChoice() {
        super();
        routerAge = new Hashtable();
    }

    public synchronized void addItem(String item, boolean oldRouter) {
        super.addItem(item);
        routerAge.put(item, new Boolean(oldRouter));
    }

    public synchronized boolean isOld(String item) {
        return(((Boolean)routerAge.get(item)).booleanValue());
    }

}

