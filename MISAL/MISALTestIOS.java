import java.net.*;
import java.io.*;
import com.marcuscom.MISAL.*;

// Here's a quick little show run example.

public class MISALTestIOS {
	public static void main(String[] argv) {
		Socket socket = null;
		MISALCiscoIOS misal = null;
		try {
			socket = new Socket("nms-7507.rtp.cisco.com", 23);
		}
		catch (UnknownHostException uhe) {
			System.err.println("Bad host: " + uhe.getMessage());
			System.exit(1);
		}
		catch (IOException ioe) {
			System.err.println(ioe.getMessage());
			System.exit(1);
		}

		try {
			misal = new MISALCiscoIOS(socket);
		}
		catch (SocketException se) {
			System.err.println(se.getMessage());
			System.exit(1);
		}
		catch (IOException ioe1) {
			System.err.println(ioe1.getMessage());
			System.exit(1);
		}
		misal.setUsername("user");
		misal.setUserPassword("passwd");
		misal.setEnablePassword("enPass");

		try {
			misal.login();
			misal.doEnable();
			misal.send(MISALCiscoIOS.ENABLE_MODE, "term len 0\r", MISALCiscoIOS.ENABLE_MODE);
			misal.send(MISALCiscoIOS.ENABLE_MODE, "show run\r", MISALCiscoIOS.ENABLE_MODE);
		}
		catch (Exception e) {
			e.printStackTrace();
			System.exit(1);
		}

		System.out.println("\n\n\n");
		System.out.println("buffer = " + misal.getBuffer());
		misal.closeSocket();
	}
}
