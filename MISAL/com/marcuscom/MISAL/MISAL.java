package com.marcuscom.MISAL;

import java.io.*;
import java.net.*;
import java.util.*;
import com.oroinc.text.regex.*;

/**-
 * Copyright &copy; 2001 Joe Clarke &lt;marcus@marcuscom.com&gt;
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * <ol>
 * <li>Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.</li>
 * <li>Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.</li>
 * <p>
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
 * </p>
 * $Id$
 * <p>
 * MISAL is the MarcusCom Intelligent Socket Abstraction Library.<br>
 * It is designed to make interacting with TCP sockets (such as telnet)
 * much easier.</p>
 *
 * @author	Joe Clarke &lt;marcus@marcuscom.com&gt;
 * @version	%I%, %G%
 * @since	JDK1.1
 */
public class MISAL implements Runnable {
	public final static int MISAL_STATE_UNKNOWN = -1;
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

	/**
	 * Create a new MISAL socket.
	 *
	 * @param socket	the <em>open</em> java.net.Socket to be 
	 *			abstracted
	 * @throws SocketException
	            if Socket is not initialized and connected
	 * @throws IOException
	 * @see			Socket
	 * @since		JDK1.1
	 */
	public MISAL(Socket socket) throws SocketException,IOException {
		if (socket == null) {
			throw new SocketException("Socket passed to MISAL cannot be null.");
		}
		this._socket = socket;
		_bis = new BufferedInputStream(this._socket.getInputStream(), DEFAULT_BUFFER_SIZE);
		_bos = new BufferedOutputStream(this._socket.getOutputStream());
		stateTable = new Hashtable();
	}

	/**
	 * Get the MISAL socket's output stream as a
	 * java.io.BufferedOutputStream.
	 *
	 * @return	java.io.BufferedOutputStream
	 * @see		Socket#getOutputStream
	 * @see		BufferedOutputStream
	 * @since	JDK1.1
	 */
	protected BufferedInputStream getInputStream() {
		return this._bis;
	}

	/**
	 * Get the MISAL socket's input stream as a
	 * java.io.BufferedInputStream.
	 *
	 * @return	java.io.BufferedInputStream
	 * @see		Socket#getInputStream
	 * @see		BufferedInputStream
	 * @since	JDK1.1
	 */
	protected BufferedOutputStream getOutputStream() {
		return this._bos;
	}

	/**
	 * Add a new MISAL state to the state table.  MISAL states are used
	 * by the state reading/setting thread to indicate where the socket
	 * is.  For example, a state can be identified by the regular
	 * expression <code>/login: ?$/</code> and a constant 
	 * STATE_LOGIN_PROMPT.
	 *
	 * @param state		an integer (usually defined as a constant)
	 *			that uniquely identifies this state.  Classes
	 *			extending MISAL can start their state numbering
	 *			at 1.
	 * @param prompt	a Perl regular expression, in the form of a
	 *			String.  When this expression is matched, the
	 *			MISAL state will be set to the value of the
	 *			<code>state</code> argument
	 * @throws MalformedPatternException
	 * @exception MalformedPatternException
	 *             if the prompt is not a valid Perl regular expression.
	 * @see			#removeState
	 * @see			Pattern
	 * @since		JDK1.1
	 */
	public synchronized void addState(int state, String prompt) throws MalformedPatternException {
		Perl5Compiler compiler = new Perl5Compiler();
		Pattern pattern = compiler.compile(prompt);
		stateTable.put(new Integer(state), pattern);
		startCheckingState();
	}

	/** 
	 * Remove a MISAL state from the state machine.
	 *
	 * @param state		integer representing the state to remove
	 * @see			#addState
	 * @since		JDK1.1
	 */
	public synchronized void removeState(int state) {
		this.stateTable.remove(new Integer(state));
	}

	/**
	 * Start the state checking thread.
	 *
	 * @see		#stopCheckingState
	 * @since	JDK1.1
	 */
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
					int state = ((Integer)keys.nextElement()).intValue();
					pattern = (Pattern)stateTable.get(new Integer(state));
					if (p5m.contains(buffer, pattern)) {
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

	private synchronized void setState(int state) {
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

	private synchronized void setBuffer(String buffer) {
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
