package com.marcuscom.MISAL;

import java.net.*;
import java.io.*;

public class MISALTest {
	public static void main(String[] argv) {
		String prompt = "login: ?$";
		int state = 1;
		Socket socket = null;
		SuperMISAL sm = null;
		try {
			socket = new Socket("sushi.marcuscom.com", 23);
		}
		catch (UnknownHostException uhe) {
			System.err.println("Bad host.");
			System.exit(1);
		}
		catch (IOException ioe) {
			System.err.println("IO Exception.");
			System.exit(1);
		}

		try {
			sm = new SuperMISAL(socket, false);
		}
		catch (SocketException se) {
			System.err.println(se.getMessage());
			System.exit(1);
		}
		catch (IOException ioe1) {
			System.err.println("IO Exception.");
			System.exit(1);
		}
		sm.addState(state, prompt);
		sm.addState(2, "Password: ?$");
		try {
			sm.send(1, "marcus\r", 2);
			sm.clearBuffer();
			sm.send(2, "mortax1\r", "]\\s*$");
		}
		catch (IllegalMISALStateException imse) {
			System.err.println(imse.getMessage());
		}
		catch (IOException ioe2) {
			System.err.println(ioe2.getMessage());
		}
		try {
			Thread.sleep(4000);
		}
		catch (InterruptedException ie) {
		}
		System.out.println("\n\n\n");
		System.out.println("buffer = " + sm.getBuffer());
		sm.closeSocket();
	}
}


		
