import java.net.*;
import java.io.*;
import com.marcuscom.MISAL.*;

public class MISALTest {
	public static void main(String[] argv) {
		Socket socket = null;
		MISAL misal = null;
		try {
			socket = new Socket("my.host.com", 23);
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
			misal = new MISAL(socket, false);
		}
		catch (SocketException se) {
			System.err.println(se.getMessage());
			System.exit(1);
		}
		catch (IOException ioe1) {
			System.err.println("IO Exception.");
			System.exit(1);
		}
		try {
			misal.addState(1, );
			misal.addState(2, "Password: ?$");
		try {
			sm.send(1, "myusername\r", 2);
			sm.clearBuffer();
			sm.send(2, "mypassword\r", "]\\s*$");
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


		
