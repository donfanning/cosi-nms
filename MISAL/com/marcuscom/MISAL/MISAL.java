package com.marcuscom.MISAL;
/*-
 * Copyright (c) 2001 Joe Clarke <marcus@marcuscom.com>
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
import java.io.*;
import java.net.*;
import java.util.*;
import com.oroinc.text.regex.*;

/**
* <p>MISAL is the MarcusCom Intelligent Socket Abstraction Library.
* It is designed to make interacting with TCP sockets (such as telnet)
* much easier.  It uses a separate thread to check the socket's state,
* and make sure data is sent at the right time.</p>
*
* @author	Joe Clarke &lt;marcus@marcuscom.com&gt;
* @version	1.0, $Id$
* @since	MISAL1.0
*/
public class MISAL implements Runnable {
    /**
     * The state of the socket when no other state matches.
     */
    public final static int MISAL_STATE_UNKNOWN = -1;

    /**
     * The state of the socket after it is closed.
     */
    public final static int MISAL_STATE_CLOSED = 0;

    /**
     * The default state checking thread interval 
     * (1 millisecond).
     */
    protected final static int MISAL_DEFAULT_SLEEP_INTERVAL = 1;

    /**
     * The default time to wait between state checking attempts
     * (100 milliseconds).
     */
    protected final static int MISAL_THREAD_SLEEP_INTERVAL = 100;
    /**
     * Number of milliseconds to wait with fast timers 
     * (10 milliseconds).
     */
    protected final static int MISAL_SHORT_THREAD_SLEEP_INTERVAL = 10;

    /**
     * The default number of retries before failing when a state match
     * is not found (1000).  This number is multiplied by the 
     * MISAL_THREAD_SLEEP_INTERVAL.
     */
    protected final static int DEFAULT_RETRIES = 1000;

    /**
     * The default size for the main accumulator buffer 
     * (1 MB).  All data read from the socket is stored in this buffer.
     */
    protected final static int DEFAULT_BUFFER_SIZE = 1*1024*1024;

    private Hashtable stateTable = null;
    private Socket _socket = null;
    private String _buffer = null;
    private String _lastBuffer = null;
    private boolean _debug = false;
    private Thread _stateChecker = null;
    private BufferedInputStream _bis = null;
    private BufferedOutputStream _bos = null;
    private int _bufferSize = this.DEFAULT_BUFFER_SIZE;
    private int _currentState = this.MISAL_STATE_UNKNOWN;
    private int _sleepInterval = this.MISAL_DEFAULT_SLEEP_INTERVAL;

    /**
     * Creates a new MISAL socket.
     *
     * @param socket	the <em>open</em> java.net.Socket to be
     * 			abstracted
     * @throws SocketException
     * if Socket is not initialized and connected
     * @throws IOException if there is a problem reading or writing Socket
     * @since MISAL1.0
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
     * Returns the MISAL socket's output stream as a
     * java.io.BufferedOutputStream.
     *
     * @see #getOutputStream()
     * @since MISAL1.0
     * @return BufferedInputStream used by MISAL
     */
    protected BufferedInputStream getInputStream() {
        return this._bis;
    }

    /**
     * Returns the MISAL socket's input stream as a
     * java.io.BufferedInputStream.
     *
     * @see #getInputStream()
     * @since MISAL1.0
     * @return BufferedOutputStream used by MISAL
     */
    protected BufferedOutputStream getOutputStream() {
        return this._bos;
    }

    /**
     * Adds a new MISAL state to the state table.  MISAL states are used
     * by the state reading/setting thread to indicate where the socket
     * is.  For example, a state can be identified by the regular
     * expression <code>/login: ?$/</code> and a constant
     * STATE_LOGIN_PROMPT.
     *
     * @see #removeState(int)
     * @since MISAL1.0
     * @param state an integer (usually defined as a constant)
     * 			that uniquely identifies this state.  Classes
     * 			extending MISAL can start their state numbering
     * 			at 1.
     * @param prompt a Perl regular expression, in the form of a
     * 			String.  When this expression is matched, the
     * 			MISAL state will be set to the value of the
     * 			<code>state</code> argument
     * @throws MalformedMISALStateException if the prompt is not a valid Perl regular expression.
     */
    public synchronized void addState(int state, String prompt) throws MalformedMISALStateException {
        Perl5Compiler compiler = new Perl5Compiler();
        Pattern pattern = null;
        try {
            pattern = compiler.compile(prompt);
        }
        catch (MalformedPatternException mfpe) {
            throw new MalformedMISALStateException(mfpe.getMessage());
        }
        stateTable.put(new Integer(state), pattern);
        startCheckingState();
    }

    /**
     * Removes a MISAL state from the state machine.
     *
     * @param state		integer representing the state to remove
     * @see			#addState(int,String)
     * @since		MISAL1.0
     */
    public synchronized void removeState(int state) {
        this.stateTable.remove(new Integer(state));
    }

    /**
     * Starts the state checking thread.
     *
     * @see		#stopCheckingState()
     * @since	MISAL1.0
     */
    protected void startCheckingState() {
        if (_stateChecker == null) {
            _stateChecker = new Thread(this);
            _stateChecker.start();
        }
    }

    /**
     * Stops the state checking thread.
     *
     * @see		#startCheckingState()
     * @since	MISAL1.0
     */
    protected void stopCheckingState() {
        if (_stateChecker != null) {
            _stateChecker.stop();
            _stateChecker = null;
        }
    }

    /**
     * Runs the state checking thread.  This method should not
     * be called directly.  Instead, use the 
     * <code>stopCheckingState()</code> and 
     * <code>startCheckingState()</code> methods.
     *
     * @see		#startCheckingState()
     * @see		#stopCheckingState()
     * @since	MISAL1.0
     */
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
                /* We preserve a separate buffer to hold the
                   last read data.  This will be useful for
                   error checking. */
                this.setBuffer(this.getLastBuffer());
                this.setLastBuffer(buffer);
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

    /**
     * Sets the MISAL state checking thread's sleep interval.  The thread
     * will wait <code>interval</code> milliseconds before checking
     * the state of the socket.
     *
     * @param interval	integer sleep interval
     * @see			#getSleepInterval()
     * @since		MISAL1.0
     */
    protected void setSleepInterval(int interval) {
        this.debug("Setting sleep interval to " + interval);
        this._sleepInterval = interval;
    }

    /**
     * Returns the MISAL state checking thread's sleep interval.  This
     * method returns the sleep interval as an integer representing the
     * number of milliseconds the state checking thread will wait before
     * checking the socket state again.
     *
     * @see #setSleepInterval(int)
     * @since MISAL1.0
     * @return the sleep interval in number of milliseconds.
     */
    protected int getSleepInterval() {
        return this._sleepInterval;
    }

    /**
     * Sets the current MISAL state.
     *
     * @param state		the state ID of a state already in the state
     *			machine
     * @see			#getState()
     * @see			#addState(int,String)
     * @see			#removeState(int)
     * @since		MISAL1.0
     */
    protected synchronized void setState(int state) {
        this.debug("Setting state to " + state);
        this._currentState = state;
    }

    /**
     * Returns the current MISAL state.
     *
     * @see #getState()
     * @see #addState(int,String)
     * @see #removeState(int)
     * @since MISAL1.0
     * @return the current state id.
     */
    public synchronized int getState() {
        return this._currentState;
    }

    /**
     * Returns the maximum allowed size of the main accumulator buffer.
     *
     * @see #setBufferSize(int)
     * @see #getBuffer()
     * @see #clearBuffer()
     * @since MISAL1.0
     * @return the buffer size in bytes.
     */
    public synchronized int getBufferSize() {
        return this._bufferSize;
    }

    /**
     * Sets the maximum allowed size of the main accumulator buffer.
     *
     * @param size	size of the buffer in bytes
     * @see		#getBufferSize()
     * @see		#getBuffer()
     * @see		#clearBuffer()
     */
    public synchronized void setBufferSize(int size) {
        this._bufferSize = size;
    }

    /**
     * Clears the main accumulator buffer.  Usually, this method is called
     * right before running a command for which you wish to save output.
     *
     * @see		#getBufferSize()
     * @see		#getBuffer()
     * @since	MISAL1.0
     */
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

    private synchronized void setLastBuffer(String buffer) {
        this.debug("Setting last read buffer to \"" + buffer + "\"");
        this._lastBuffer = buffer;
    }

    /**
     * Returns the output of the temporary buffer.  This buffer usually
     * stores the output from the last run command.  It is useful for
     * doing error checking.
     *
     * @see #getBuffer()
     * @since MISAL1.0
     * @return the contents of the last read from the MISAL socket as a string.
     */
    public synchronized String getLastBuffer() {
        return this._lastBuffer;
    }

    /**
     * Returns the contents of the main accumulator buffer.  This buffer
     * contains all the data fro the sockets output stream since the last
     * call to <code>clearBuffer</code>.  The output will include the
     * contents of the current temporary buffer as well.
     *
     * @see #clearBuffer()
     * @see #getLastBuffer()
     * @since MISAL1.0
     * @return the accumulated MISAL buffer as a string.
     */
    public synchronized String getBuffer() {
        return this._buffer.concat(this.getLastBuffer());
    }

    /**
     * Tells whether or not debugging is enabled.
     *
     * @see #toggleDebug()
     * @since MISAL1.0
     * @return true if debugging is enabled, false otherwise.
     */
    public boolean getDebug() {
        return this._debug;
    }

    /**
     * Toggle the debugging state.
     *
     * @return	The debugging state after being toggled
     * @see		#getDebug()
     * @since	MISAL1.0
     */
    public boolean toggleDebug() {
        this._debug = this._debug ? false : true;
        this.debug("Debugging set to " + this._debug);
        return this._debug;
    }

	/**
         * Send data on the MISAL socket.
         *
         * @since MISAL 1.0
         * @param data the data to send on the socket
         * @param expect a string indicating what to expect back from the host
         * @throws IllegalMISALStateException if the state, <CODE>expect</CODE>, is not reached.
         * @throws IOException if any miscellaneous IO error occurs.
         */
    public void send(String data, String expect) throws IllegalMISALStateException, IOException {
        this.send(MISAL_STATE_UNKNOWN, data, expect, 0, 0);
    }

	/**
         * Send data on the MISAL socket.
         *
         * @since MISAL 1.0
         * @param data the data to send on the socket
         * @param expectState an integer indicating what to expect back from the
         * host
         * @throws IllegalMISALStateException if the state, <CODE>expectState</CODE>, is not reached.
         * @throws IOException if any miscellaneous IO error occurs.
         */
    public void send(String data, int expectState) throws IllegalMISALStateException, IOException {
        this.send(MISAL_STATE_UNKNOWN, data, null, expectState, 0);
    }

	/**
         * Send data on the MISAL socket.
         *
         * @since MISAL 1.0
         * @param state the initial state to require before sending data on the
         * socket
         * @param data the data to send on the socket
         * @param expect a String indicating what to expect back from the host
         * @throws IllegalMISALStateException if the state, <CODE>expect</CODE> is not reached
         * @throws IOException if any miscellaneous IO error occurs.
         */
    public void send(int state, String data, String expect) throws IllegalMISALStateException, IOException {
        this.send(state, data, expect, 0, 0);
    }

	/**
         * Send data on the MISAL socket.
         *
         * @since MISAL 1.0
         * @param state the initial state to require before sending data on the
         * socket
         * @param data the data to send on the socket
         * @param expectState an integer indicating what to expect back from the
         * host
         * @throws IllegalMISALStateException if the state, <CODE>expectState</CODE>, is not reached.
         * @throws IOException if any miscellaneous IO error occurs.
         */
    public void send(int state, String data, int expectState) throws IllegalMISALStateException, IOException {
        this.send(state, data, null, expectState, 0);
    }

	/**
         * Send data on the MISAL socket.
         *
         * @since MISAL 1.0
         * @param state the initial state to require before sending data on the
         * socket
         * @param data the data to send on the socket
         * @param expect a string indicating what to expect back from the host
         * @param wait number of retries before timing out if expect state
         * is not met
         * @throws IllegalMISALStateException if the state, <CODE>expect</CODE>, is not reached.
         * @throws IOException if any miscellaneous IO exception occurs.
         */
    public void send(int state, String data, String expect, int wait) throws IllegalMISALStateException, IOException {
        this.send(state, data, expect, 0, wait);
    }

	/**
         * Send data on the MISAL socket.
         *
         * @since MISAL 1.0
         * @param state the initial state to require before sending data on the
         * socket
         * @param data the data to send on the socket
         * @param expectState an integer indicating what to expect back from the
         * host
         * @param wait number of retries before timing out if expect state
         * is not met
         * @throws IllegalMISALStateException if the state, <CODE>expectState</CODE>, is not reached.
         * @throws IOException if any miscellaneous IO error occurs.
         */
    public void send(int state, String data, int expectState, int wait) throws IllegalMISALStateException, IOException {
        this.send(state, data, null, expectState, wait);
    }

	/**
         * Send data on the MISAL socket.  This overloaded version of send() should
         * not be normally used.  Instead, use one of the other send() methods.
         *
         * @see #expect(int,int)
         * @since MISAL 1.0
         * @param state the initial state to require before sending data on the
         * socket
         * @param data the data to send on the socket
         * @param expect a string indicating what to expect back from the host
         * @param expectState an integer indicating what to expect back from the
         * host
         * @param wait number of retries before timing out if expect state
         * is not met
         * @throws IllegalMISALStateException if the state,<CODE>expectState</CODE>, or the state <CODE>expect</CODE>
         * are not reached.
         * @throws IOException if any miscellaneous IO error occurs.
         */
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
        /* Set the state to be unknown while we wait to find out
           what the resultant state will be. */
        this.setState(this.MISAL_STATE_UNKNOWN);
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

	/**
         * Wait for a certain state for proceeding.
         *
         * @see #send(int,String,String,int,int)
         * @since MISAL 1.0
         * @param state an integer indicating the state to wait for
         * @return true if state is reached, fales otherwise
         */
    protected boolean expect(int state) {
        return this.expect(state, this.DEFAULT_RETRIES);
    }

	/**
         * Wait for a certain string of data from the remote host before
         * proceeding.  For example, wait for an enable prompt before doing
         * a <code>show run</code>.
         *
         * @see #send(int,String,String,int,int)
         * @since MISAL 1.0
         * @param prompt string to expect from remote host
         * @return true if <CODE>prompt</CODE> is reached, false otherwise.
         */
    protected boolean expect(String prompt) {
        return this.expect(prompt, this.DEFAULT_RETRIES);
    }

	/**
         * Wait for a certain state for proceeding.
         *
         * @see #send(int,String,String,int,int)
         * @since MISAL 1.0
         * @param state an integer indicating the state to wait for
         * @param tries number of tries before giving up on the expected state
         * @return true is <CODE>prompt</CODE> is reached, false otherwise.
         */
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

	/**
         * Wait for a certain string of data from the remote host before
         * proceeding.  For example, wait for an enable prompt before doing
         * a <code>show run</code>.
         *
         * @see #send(int,String,String,int,int)
         * @since MISAL 1.0
         * @param prompt string to expect from remote host
         * @param tries number of tries before giving up on the expected state
         * @return true if <CODE>prompt</CODE> is seen, false otherwise.
         */
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

    /**
     * Prints a debugging message.  The message will only be printed
     * if debugging is enabled.
     *
     * @param msg	The message to be printed
     * @see		#getDebug()
     * @see		#toggleDebug()
     * @since	MISAL1.0
     */
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

    /**
     * Closes the MISAL socket.  Once you are done with the socket, you
     * can have MISAL close it.  This will stop the state checking thread.
     *
     * @since	MISAL1.0
     */
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
