import	java.awt.*;
import	java.awt.event.*;
import	java.net.*;
import	java.applet.*;
import	java.util.*;
import	java.io.*;

public class Throughputter extends Applet
{
	static final int	MAX_XFER_TIME = 10;	// 10 seconds max
	
	String			codeBase;
	
	TextField		status;
	TextField		compFileSpeed;
	TextField		uncompFileSpeed;
	Label			uncompLabel;
	Label			compLabel;
	Label			statusLabel;
	Button			start;
	boolean			valid = false;		// Whether or not the results are valid.
		
	Frame			f;
	
	public void
	init() {
		valid = false;
		statusLabel = new Label("Status: ");
		status = new TextField();
		status.setEditable(false);
		status("Initializing...");
		
		start = new Button("Start");
		compLabel = new Label("Compressible Stream Speed: ");
		compFileSpeed = new TextField("[Compressible Speed]");
		compFileSpeed.setEditable(false);
		uncompLabel = new Label("Random Character Speed: " );
		uncompFileSpeed = new TextField("[Uncompressible Speed]");
		uncompFileSpeed.setEditable(false);
		
		
		setLayout( new GridLayout(4,2) );
		add( compLabel );
		add( compFileSpeed );
		add( uncompLabel );
		add( uncompFileSpeed );
		add( status );
		add( start );
		
		if( codeBase == null ) 
			codeBase = new String( this.getCodeBase().toString() );
		
		validate();
		status("Initialized.");
	}
	
	public boolean
	action( Event e, Object o ) {
		run();
		repaint();
		return false;
	}
	
	public void
	run() {

		compFileSpeed.setText("[Compressed Speed]");
		uncompFileSpeed.setText("[Uncompressed Speed]");
		status("Ready.");
//		clearFields();		
		uncompSpeed();
		compSpeed();
		if( valid )
			status("Done!");
	}
	
	void
	log( String s )
	{
		System.out.println(s);
	}

	void
	status( String s ) {
		status.setText(s);
		repaint();
	}
	
	public void
	start() { 
	}

	public void
	compSpeed( )	{
		double speed = 0.0;
		status("Calculating compressed throughput.");
		speed = getSpeed( codeBase + "testfile_w" );
		compFileSpeed.setText( Double.toString(speed) + " kbytes / sec.");
		repaint();
	}
	
	public void
	uncompSpeed(  ) {
		double speed = 0.0;		
		status("Calculating uncompressed throughput.");
		speed = getSpeed( codeBase +  "testfile_random" );
		uncompFileSpeed.setText( Double.toString(speed) + " kbytes / sec.");		
		repaint();
	}

	
	public void
	stop() {}
	
	public void
	paint() {}

	public void
	focusGained( FocusEvent e ) {	
		repaint();
	}
	
	public void
	setCodeBase( String s )
	{
		codeBase = new String(s);
	}

	public double
	getSpeed( String s ) {
		long	dT = 0;
		double	updateTime = 0.0;
		int	bytes = 0;
		int	iBytes = 0;
		char	data[];
		data = new char[1024];
		try {
			URL		url = new URL(s);
			dT = System.currentTimeMillis();
			updateTime = dT;
			BufferedReader bin = new BufferedReader( new InputStreamReader( url.openStream()) );
			String line;
			while( (iBytes=bin.read(data, 0, 1024)) != -1) {
				bytes += iBytes;
				if( (System.currentTimeMillis() - updateTime) > 1000 ) {
					status("Currently " + bytes / (System.currentTimeMillis() - dT) + " kbytes / sec." );
					updateTime = System.currentTimeMillis();
				}
				if( (System.currentTimeMillis()-dT) > MAX_XFER_TIME*1000 )
					break;
			}
			dT = System.currentTimeMillis() - dT;

		} catch (Exception e) {
			status("Unable to connect to host.");	
			e.printStackTrace();
			valid = false;
			return 0;
		}
		System.out.println( bytes + " bytes in " + dT + " ms." );
		valid = true;
		return (bytes/dT);
	}
	
	public String
	getAppletInfo() { return "Speed Test v.1 by Weston Hopkins / Cisco"; }
	
	public static void main(String[] args) {
        
        //Create a new window.
        Frame f = new Frame("Converter Applet/Application");
        
        f.addWindowListener(new WindowAdapter() {
		public void windowClosing(WindowEvent e) {
		System.exit(0);
		}
	});

	//Create a Converter instance.
	Throughputter throughputter = new Throughputter();
	
	throughputter.setCodeBase("http://www.xentao.com/netrobust/throughputter/");

	//Initialize the Converter instance.
	throughputter.init();

	//Add the Converter to the window and display the window.
	f.add("Center", throughputter);
	f.pack();        //Resizes the window to its natural size.
	f.setVisible(true);
	}
}