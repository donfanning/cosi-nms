package com.marcuscom.MISAL;

import java.io.*;
import java.net.*;
import java.util.*;
import com.oroinc.text.regex.*;

public class MISAL implements Runnable {
	public final static int MISAL_STATE_UNKNOWN = -2;
	public final static int MISAL_STATE_INITIAL = -1;
	public final static int MISAL_STATE_CLOSED = 0;

	protected final static int MISAL_DEFAULT_SLEEP_INTERVAL = 1;
	protected final static int MISAL_THREAD_SLEEP_INTERVAL = 100;
	protected final static int MISAL_SHORT_THREAD_SLEEP_INTERVAL = 10;
	protected final static int DEFAULT_RETRIES = 1000;
	protected final static int DEFAULT_BUFFER_SIZE = 1*1024*1024;

	private Hashtable stateTable = null;
	private Socket _socket = null;
	private String _buffer = null;
	private boolean _debug = false;
	private Thread _stateChecker = null;
	private BufferedInputStream _bis = null;
	private BufferedOutputStream _bos = null;
	private int _bufferSize = this.DEFAULT_BUFFER_SIZE;
	private int _currentState = this.MISAL_STATE_UNKNOWN;
	private int _sleepInterval = this.MISAL_DEFAULT_SLEEP_INTERVAL;

	public MISAL(Socket socket, boolean debug) throws SocketException,IOException {
		this(socket, debug, DEFAULT_BUFFER_SIZE);
	}

	public MISAL(Socket socket) throws SocketException, IOException {
		this(socket, false, DEFAULT_BUFFER_SIZE);
	}

	public MISAL(Socket socket, int bufSize) throws SocketException, IOException {
		this(socket, false, bufSize);
	}

	public MISAL(Socket socket, boolean debug, int bufSize) throws SocketException,IOException {
		if (socket == null) {
			throw new SocketException("Socket passed to MISAL cannot be null.");
		}
		this._socket = socket;
		this._debug = debug;
		this._bufferSize = bufSize;
		_bis = new BufferedInputStream(this._socket.getInputStream(), bufSize);
		_bos = new BufferedOutputStream(this._socket.getOutputStream());
		stateTable = new Hashtable();
	}

	protected BufferedInputStream getInputStream() {
		return this._bis;
	}

	protected BufferedOutputStream getOutputStream() {
		return this._bos;
	}

	public synchronized void addState(int stateId, String prompt) throws MalformedPatternException {
		Perl5Compiler compiler = new Perl5Compiler();
		Pattern pattern = compiler.compile(prompt);
		stateTable.put(pattern, new Integer(stateId));
		startCheckingState();
	}

	public synchronized void removeState(String prompt) {
		this.stateTable.remove(prompt);
	}

	protected void startCheckingState() {
		if (_stateChecker == null) {
			_stateChecker = new Thread(this);
			_stateChecker.start();
		}
	}

	protected void stopCheckingState() {
		if (_stateChecker != null) {
			_stateChecker.stop();
			_stateChecker = null;
		}
	}

	public void run() {
		while(true) {
			if (stateTable.isEmpty()) {
				/* We don't want to hit a null pointer if
				   someone empties the state table on us */
				this.stopCheckingState();
				return;
			}

			if (_socket == null) {
				this.setState(this.MISAL_STATE_CLOSED);
				this.stopCheckingState();
				return;
			}
		
			String buffer = this._readAll();
			if (buffer != null) {
				this.setBuffer(buffer);
				Enumeration keys = stateTable.keys();
				Perl5Matcher p5m = new Perl5Matcher();
				Pattern pattern = null;
				while(keys.hasMoreElements()) {
					pattern = (Pattern)keys.nextElement();
					if (p5m.contains(buffer, pattern)) {
						int state = ((Integer)stateTable.get(pattern)).intValue();
						this.setState(state);
					}
				}
			}
			try {
				Thread.sleep(this.getSleepInterval());
			}
			catch (InterruptedException ie) {
			}
		}
	}

	protected void setSleepInterval(int interval) {
		this.debug("Setting sleep interval to " + interval);
		this._sleepInterval = interval;
	}

	protected int getSleepInterval() {
		return this._sleepInterval;
	}

	public synchronized void setState(int state) {
		this.debug("Setting state to " + state);
		this._currentState = state;
	}

	public synchronized int getState() {
		return this._currentState;
	}

	public synchronized int getBufferSize() {
		return this._bufferSize;
	}

	public synchronized void setBufferSize(int size) {
		this._bufferSize = size;
	}

	public synchronized void clearBuffer() {
		this.setBuffer(null);
	}

	public synchronized void setBuffer(String buffer) {
		if (buffer == null || this._buffer == null || this._buffer.length() >= this.getBufferSize()) {
			this.debug("Setting buffer to \"" + buffer + "\"");
			this._buffer = buffer;
		}
		else {
			this.debug("Appending \"" + buffer + "\" to buffer");
			this._buffer = this._buffer.concat(buffer);
		}
	}

	public synchronized String getBuffer() {
		return this._buffer;
	}

	public synchronized boolean getDebug() {
		return this._debug;
	}

	public synchronized boolean toggleDebug() {
		this._debug = this._debug ? false : true;
		this.debug("Debugging set to " + this._debug);
		return this._debug;
	}

	public void send(int state, String data, String expect) throws IllegalMISALStateException, IOException {
		this.send(state, data, expect, 0, 0);
	}

	public void send(int state, String data, int expectState) throws IllegalMISALStateException, IOException {
		this.send(state, data, null, expectState, 0);
	}

	public void send(int state, String data, String expect, int wait) throws IllegalMISALStateException, IOException {
		this.send(state, data, expect, 0, wait);
	}

	public void send(int state, String data, int expectState, int wait) throws IllegalMISALStateException, IOException {
		this.send(state, data, null, expectState, wait);
	}

	protected void send(int state, String data, String expect, int expectState, int wait) throws IllegalMISALStateException, IOException {
		this.debug("Entering send(int, String, String, int, int) method.");
		boolean result = false;
		int currState = this.MISAL_STATE_UNKNOWN;
		byte b[] = null;
		if (wait == 0) wait = this.DEFAULT_RETRIES;
		for(int i = 1; i <= wait; i++) {
			currState = this.getState();
			this.debug("i = " + i + " and currState = " + currState);
			if (currState == state) break;
			try {
				Thread.sleep(this.MISAL_THREAD_SLEEP_INTERVAL);
			}
			catch (InterruptedException ie) {}
		}
		if (currState != state) {
			throw new IllegalMISALStateException("Needed state " + state + ", but found state " + currState);
		}
		b = new byte[data.length()];
		b = data.getBytes();
		this.debug("Sending data: " + data);
		this._bos.write(b, 0, b.length);
		this._bos.flush();
		if (expect != null) {
			this.debug("Expecting text: \"" + expect + "\"");
			result = this.expect(expect, wait);
		}
		else {
			this.debug("Expecting state: " + expectState);
			result = this.expect(expectState, wait);
		}

		if (!result) {
			throw new IllegalMISALStateException("Invalid expect state");
		}
	}

	protected boolean expect(int state) {
		return this.expect(state, this.DEFAULT_RETRIES);
	}

	protected boolean expect(String prompt) {
		return this.expect(prompt, this.DEFAULT_RETRIES);
	}

	protected boolean expect(int state, int tries) {
		this.debug("Entering method expect(int, int)");
		for(int i = 1; i <= tries; i++) {
			this.debug("i = " + i + " and state = " + this.getState());
			if (this.getState() == state) {
				return true;
			}
			try {
				Thread.sleep(this.MISAL_THREAD_SLEEP_INTERVAL);
			}
			catch (InterruptedException ie) {}
		}
		return false;
	}

	protected boolean expect(String prompt, int tries) {
		this.debug("Entering method expect(String, int)");
		Perl5Compiler compiler = new Perl5Compiler();
		Perl5Matcher matcher = new Perl5Matcher();
		Pattern pattern = null;
		for(int i = 1; i <= tries; i++) {
			String buffer = this.getBuffer();
			this.debug("i = " + i + " buffer = \"" + buffer + "\"");
			try {
				pattern = compiler.compile(prompt);
			}
			catch (MalformedPatternException mpe) {
				return false;
			}
			if (buffer != null) {
				if (matcher.contains(this.getBuffer(), pattern)) {
					this.debug("Found a buffer match!");
					return true;
				}
			}
			try {
				Thread.sleep(this.MISAL_THREAD_SLEEP_INTERVAL);
			}
			catch (InterruptedException ie) {}
		}
		return false;
	}

	public void debug(String msg) {
		if (this.getDebug()) {
			System.err.println("DEBUG: " + msg);
		}
	}

	private String _readAll() {
		byte b[] = null;
		try {
			if (_bis.available() == 0) {
				return null;
			}
			b = new byte[_bis.available()];
			int t;
			int y = 0;
			byte[] obuf = new byte[4];
			while (_bis.available() > 0) {
				t = _bis.read();
				if (t != 255) {
					/* If not a negotiation character,
					   it needs to be read as data. */
					b[0] = (byte)t;
					break;
				}
				obuf[0] = (byte)255;
				t = _bis.read();
				if (t == 251 || t == 252) {
					y = 254;
				}
				if (t == 253 || t == 254) {
					y = 252;
				}
				if (y > 0) {
					obuf[1] = (byte)y;
					obuf[2] = (byte)_bis.read();
					_bos.write(obuf, 0, 3);
					_bos.flush();
					y = 0;
				}
			}

			if (_bis.available() == 0) {
				return null;
			}
			/* This starts at 1 now because we load the first
			   character in during the negotiation code. */
			int result = _bis.read(b, 1, _bis.available());
			if (result == 0) {
				return null;
			}
		}
		catch (IOException ioe) {
			return null;
		}
		this.debug("Read \"" + new String(b) + "\" from socket input stream");
		return new String(b);
	}

	public void closeSocket() {
		this.debug("Closing socket ...");
		if (this._socket != null) {
			try {
				this._socket.close();
			}
			catch (IOException ioe) {
			}
			this._socket = null;
		}
	}
}
