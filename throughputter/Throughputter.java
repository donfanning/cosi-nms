// Throughputter.java
//// Connects to a web server and fetches 2 files (testfile_w, testfile_random)
//// and calculates the throughput. Just put all of the files (index.html, Throughputter.class
//// testfile_*) in a directory and load the index.html file in a browser. 
//// testfile_w: Is just 1M of the char 'w', over and over and over, which is compressible
//// testfile_random: Is, you guessed it, random 8bit characters.

import	java.awt.*;
import	java.awt.event.*;
import	java.net.*;
import	javax.swing.*;
import	java.applet.*;
import	java.util.*;
import	java.io.*;
import	java.text.*;

public class Throughputter extends Applet
{
	static final int	MAX_XFER_TIME = 10;	// 10 seconds max
	
	String			codeBase;	// Base of the URL of the page
	
	TextField		status;		// Status bar mesage
	TextField		compFileSpeed;	// Compressed file speed (testfile_w)
	TextField		uncompFileSpeed;
	Label			uncompLabel;	// Uncompressed (testfile_random)
	Label			compLabel;
	Label			statusLabel;
	Button			start;			// Start button
	DecimalFormat	decFormat;
	
	

	////////////////////////////////////////////////////////////////////////
	// init(): Initializes variables and stuff
	////////////////////////////////////////////////////////////////////////
	public void
	init() {
		decFormat = new DecimalFormat("#######.##");
		
		statusLabel = new Label("Status: ");
		status = new TextField();
		status.setEditable(false);
		status("Initializing...");
		start = new Button("Start");
		compLabel = new Label("Compressible Stream: ");		
		compFileSpeed = new TextField("[Compressed Speed]");		
		compFileSpeed.setEditable(false);
		uncompLabel = new Label("Random Character Stream: " );
		uncompFileSpeed = new TextField("[Uncompressed Speed]");
		uncompFileSpeed.setEditable(false);

		codeBase = new String( this.getCodeBase().toString() );    

		Font fontArial = new Font("Arial", Font.BOLD, 12 );		// Makes it purty
		compLabel.setFont(fontArial);
		compFileSpeed.setFont(fontArial);		
		uncompLabel.setFont(fontArial);
		uncompFileSpeed.setFont(fontArial);
		status.setFont(fontArial);
		start.setFont(fontArial);
		
		setLayout( new GridLayout(4,2) );
		add( compLabel );
		add( compFileSpeed );
		add( uncompLabel );
		add( uncompFileSpeed );
		add( status );
		add( start );
		repaint();
		validate();
		status("Initialized.");
	}
	
	////////////////////////////////////////////////////////////////////////
	// action(): Does this when the start button is hit.
	////////////////////////////////////////////////////////////////////////
	public boolean
	action( Event e, Object o ) {
		run();
		repaint();
		return false;
	}
	
	////////////////////////////////////////////////////////////////////////
	// run():
	////////////////////////////////////////////////////////////////////////
	public void
	run() {

		compFileSpeed.setText("[Compressed Speed]");
		uncompFileSpeed.setText("[Uncompressed Speed]");
		status("Ready.");
		compSpeed();		
		uncompSpeed();
		status("Done!");
	}
	
	////////////////////////////////////////////////////////////////////////
	// log():
	////////////////////////////////////////////////////////////////////////
	void
	log( String s )	{ System.out.println(s); }

	////////////////////////////////////////////////////////////////////////
	// status(): Prints to the status bar
	////////////////////////////////////////////////////////////////////////
	void
	status( String s ) {
		System.out.println(s);
		status.setText(s);
		repaint();
	}

	////////////////////////////////////////////////////////////////////////
	// start():
	////////////////////////////////////////////////////////////////////////
	public void
	start() { }

	////////////////////////////////////////////////////////////////////////
	// compSpeed(): Calculates the transfer speed of testfile_w
	////////////////////////////////////////////////////////////////////////
	public void
	compSpeed( ) {
		int speed = 0;
		status("Calculating compressed throughput.");
		speed = getSpeed( codeBase + "testfile_w" );
//		compFileSpeed.setText( Double.toString(speed) + " kbps.");
		if( speed > 300 ) {
			compFileSpeed.setText(  speed + " kbps is too high for a modem." );
		} else {
			compFileSpeed.setText( speed + " kbps.");
		}
		repaint();
	}

	////////////////////////////////////////////////////////////////////////
	// uncompSpeed(): Calculates the transfer speed of testfile_random
	////////////////////////////////////////////////////////////////////////
	public void
	uncompSpeed(  ) {
		int speed = 0;		
		status("Calculating uncompressed throughput.");
		speed = getSpeed( codeBase +  "testfile_random" );
//		uncompFileSpeed.setText( Double.toString(speed) + " kbps.");
		if( speed > 60 ) {
			uncompFileSpeed.setText(  speed + " kbps is too high for a modem." );
		} else {
			uncompFileSpeed.setText( speed + " kbps.");
		}
		repaint();
	}

	////////////////////////////////////////////////////////////////////////
	// stop():
	////////////////////////////////////////////////////////////////////////
	public void
	stop() {}
	
	////////////////////////////////////////////////////////////////////////
	// focusGained(): Repaint the B if you get focus.
	////////////////////////////////////////////////////////////////////////
	public void
	focusGained( FocusEvent e ) {	
		repaint();
	}


	////////////////////////////////////////////////////////////////////////
	// getSpeed(): Calculates the transfer speed of a file over http.
	//// returns in kbps. (bits * 1000 / sec)
	////////////////////////////////////////////////////////////////////////
	public int
	getSpeed( String s ) {
		long	dT = 0;		// The change in time
		double	updateTime = 0.0;	// For updating the display every 1 sec
		int	bytes = 0;	// Total bytes sent
		int	iBytes = 0;	// Incremental bytes sent
		char	data[]; // Buffer for the transfer
		String	busyString;
		
		data = new char[1024];
		busyString = new String();
		
		try {
			URL		url = new URL(s);
			dT = System.currentTimeMillis();
			updateTime = dT;
			BufferedReader bin = new BufferedReader( new InputStreamReader( url.openStream()) );
			String line;
			while( (iBytes=bin.read(data, 0, 1024)) != -1) {
				bytes += iBytes;
				if( (System.currentTimeMillis() - updateTime) > 1000 ) {
					if( busyString.length() >= 5 )
						busyString = ".";
					else
						busyString += ".";
					status("Currently " + (bytes*8) / (System.currentTimeMillis() - dT) + " kbps." + busyString );
					updateTime = System.currentTimeMillis();
					repaint();
				}
/*	This causes a problem with old Netscapes when they cache the testfile_*
 *				if( (System.currentTimeMillis()-dT) > MAX_XFER_TIME*1000 )
 *					break;
**/
			}
			dT = System.currentTimeMillis() - dT;

		} catch (Exception e) {
			status("Unable to retrieve file.");
			e.printStackTrace();
			return -1;
		}
		System.out.println( bytes*8 + " bits in " + dT + " ms." );
		return ((int)(bytes*8)/(int)dT);
	}
	
	
	////////////////////////////////////////////////////////////////////////
	// getAppletInfo(): I don't really know what this does
	////////////////////////////////////////////////////////////////////////
	public String
	getAppletInfo() { return "Speed Test v.1 by Weston Hopkins / Cisco"; }
}
