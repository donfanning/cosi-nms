import java.net.*;
import java.io.*;
import com.marcuscom.MISAL.*;
import com.oroinc.text.regex.*;

public class MISALTest {
	public static void main(String[] argv) {
		Socket socket = null;
		MISAL misal = null;
		try {
			socket = new Socket("my.host.com", 23);
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
			misal = new MISAL(socket);
		}
		catch (SocketException se) {
			System.err.println(se.getMessage());
			System.exit(1);
		}
		catch (IOException ioe1) {
			System.err.println(ioe1.getMessage());
			System.exit(1);
		}
		try {
			misal.addState(1, "login: ?$");
			misal.addState(2, "[Pp]assword: ?$");
		}
		catch (MalformedPatternException mfpe) {
			System.err.println(mfpe.getMessage());
		}
		try {
			misal.send(1, "myusername\r", 2);
			misal.clearBuffer();
			misal.send(2, "mypassword\r", "]\\s*$");
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
		System.out.println("buffer = " + misal.getBuffer());
		misal.closeSocket();
	}
}
