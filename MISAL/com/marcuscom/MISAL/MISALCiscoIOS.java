package com.marcuscom.MISAL;
/*-
 * Copyright (c) 2001-2004 Joe Clarke <marcus@marcuscom.com>
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
import org.apache.oro.text.regex.*;

/** <p>MISALCiscoIOS is an extension of MISAL designed to interact with Cisco
 * IOS devices.  It allows one to telnet into an IOS device, become enabled, and
 * execute IOS commands.</p>
 * @author Joe Clarke &lt;marcus@marcuscom.com&gt;
 * @version $Id$
 * @since MISAL 1.0
 */
public class MISALCiscoIOS extends MISAL {
    /** The state matching the normal Cisco IOS prompt (usually a prompt ending in
     * '&gt;').
     */
    public static final int DISABLE_MODE = 1;
    /** The state matching the normal Cisco IOS enable prompt (usually a prompt ending in '#').
     */
    public static final int ENABLE_MODE = 2;
    /** The state matching IOS config mode (usually a prompt ending in "(config)#").
     */
    public static final int CONFIG_MODE = 3;
    /** The state matching the IOS interface config mode (usually a prompt ending in "(config-if)#").
     */
    public static final int CONFIG_MODE_IF = 4;
    /** The state matching a config mode other than normal config and interface config.
     */
    public static final int CONFIG_MODE_OTHER = 5;
    /** The state matching a AAA username prompt (usually "Username:").
     */
    public static final int USER_PROMPT = 6;
    /** The state matching a password prompt (usually "Password:").
     */
    public static final int PASSWORD_PROMPT = 7;

    /** The state matched when no authentication level is known (e.g. before one even begins to log into an IOS device).
     */
    protected static final int AUTH_UNKNOWN = 0;
    /** The state matched when needing to authenticate using a VTY password.
     */
    protected static final int AUTH_VTY = 1;
    /** The state matched when needing to authenticate with a AAA (or local) username.
     */
    protected static final int AUTH_USER = 2;
    /** The state matched when needing to enter an enable password when no enable username is required.
     */
    protected static final int AUTH_VTY_ENABLE = 3;
    /** The state matched when needing to enter an enable username.
     */
    protected static final int AUTH_USER_ENABLE = 4;
    /** The state matched when needing to use an enable TACACS username to login (i.e. you login and immediately become enabled).
     */
    protected static final int AUTH_ENABLE_TACACS = 5;

    private String _vtyPw = null;
    private String _enablePw = null;
    private String _user = null;
    private String _userPw = null;
    private String _errorMessage = null;

    /** Creates a new MISALCiscoIOS socket.
     * @since MISAL1.0
     * @param socket the <I>open</I> java.net.Socket to be abstracted
     * @throws SocketException if Socket is not initialized and connected
     * @throws IOException if there is a problem reading or writing Socket
     */
    public MISALCiscoIOS(Socket socket) throws SocketException, IOException {
        super(socket);

        /* Add Cisco-specific states */
        try {
            /* Standard disable prompt */
            addState(this.DISABLE_MODE, ">$");
            /* Standard enable prompt */
            addState(this.ENABLE_MODE, "[^\\)]#$");
            /* Vanilla config prompt */
            addState(this.CONFIG_MODE, "\\(config\\)#$");
            /* Config interface prompt */
            addState(this.CONFIG_MODE_IF, "\\(config-if\\)#$");
            /* Some other config prompt */
            addState(this.CONFIG_MODE_OTHER, "\\(config-[^i][^f]\\)#$");
            addState(this.USER_PROMPT, "^Username:\\s.*$");
            addState(this.PASSWORD_PROMPT, "^Password:\\s.*$");
        }
        /* This code should not generate an exception.  These
           patterns are tested. */
        catch (MalformedMISALStateException mmse) {}
    }

    /** Set the enable password.  By default, this is null.
     * @param enablePw the enable password to use
     * @see #setVtyPassword(String)
     * @see #setUserPassword(String)
     */
    public void setEnablePassword(String enablePw) {
        this._enablePw = enablePw;
    }

    /** Set the AAA or local username (if needed).  By default, this is null.
     * @param username the username to use for AAA or local authentication
     * @see #setUserPassword(String)
     */
    public void setUsername(String username) {
        this._user = username;
    }

    /** Set the VTY password.  By default, this is null.
     * @param vtyPw the VTY password to use for basic authentication
     */
    public void setVtyPassword(String vtyPw) {
        this._vtyPw = vtyPw;
    }

    /** Set the user password for AAA or local authentication.  By default, this is null.
     * @param userPw the user password to use for AAA or local authentication
     * @see #setUsername(String)
     */
    public void setUserPassword(String userPw) {
        this._userPw = userPw;
    }

    /** Set the username prompt for AAA or local authentication.  By default, this is "Username:".
     * @param prompt the value of the username prompt
     * @throws MalformedMISALStateException if <CODE>prompt</CODE> is not a valid MISAL state
     * @see #setPasswordPrompt(String)
     */
    public void setUserPrompt(String prompt) throws MalformedMISALStateException {
        addState(this.USER_PROMPT, prompt);
    }

    /** Set the password prompt for AAA or local authentication.  By default, this is "Password:".
     * @param prompt the value of the password prompt
     * @throws MalformedMISALStateException if <CODE>prompt</CODE> is not a valid MISAL state
     * @see #setUserPrompt(String)
     */
    public void setPasswordPrompt(String prompt) throws MalformedMISALStateException {
        addState(this.PASSWORD_PROMPT, prompt);
    }

    /** Retrieve the last error message from the MISAL socket.  If no error message was encountered, this is null.
     * @return last error message as a string
     * @see #errorOccurred()
     */
    public String getLastErrorMessage() {
        return this._errorMessage;
    }

    private void setLastErrorMessage(String message) {
        this._errorMessage = message;
    }

    private int getAuthScheme(int state) throws InsufficientCredentialsException {
        int auth = this.AUTH_UNKNOWN;
        switch(state) {
        case DISABLE_MODE:
            if (this._vtyPw == null && (this._user == null || this._userPw == null)) {
                throw new InsufficientCredentialsException("Not enough credentials specified to log into device.");
            }
            else if (this._vtyPw != null) {
                auth = this.AUTH_VTY;
            }
            else {
                auth = this.AUTH_USER;
            }
            break;
        case ENABLE_MODE:
            if (this._enablePw != null && this._user != null && this._userPw != null) {
                auth = this.AUTH_USER_ENABLE;
            }
            else if (this._enablePw != null && this._vtyPw != null) {
                auth = this.AUTH_VTY_ENABLE;
            }
            else if (this._enablePw == null && this._user != null && this._userPw != null) {
                auth = this.AUTH_ENABLE_TACACS;
            }
            else {
                throw new InsufficientCredentialsException("Not enough credentials specified to gain enable privileges on device.");
            }
            break;
        }
        return auth;
    }

    /** Perform the login dialog with connected IOS device.  The expected result is either the disabled prompt or the enable prompt.
     * @throws InsufficientCredentialsException if the authentication information cannot be used to make a successful login
     * @throws IllegalMISALStateException if a valid logged in state is not reached
     * @throws IOException if an error occurs reading or writing the MISAL socket
     * @see #doEnable()
     * @see #doDisable()
     * @see #doConfig()
     */
    public void login() throws InsufficientCredentialsException, IllegalMISALStateException, IOException {
        switch (this.getAuthScheme(this.DISABLE_MODE)) {
        case AUTH_VTY:
            /* Expect a Password: prompt */
            send(this.PASSWORD_PROMPT, this._vtyPw + "\r", "[#>]$");
            /* If we don't get what we expect, throw
               the IllegalMISALStateException. */
            break;
        case AUTH_USER:
            try {
                /* Expect either ENABLE or DISABLE MODE
                   as we could be using enable TACACS */
                send(this.USER_PROMPT, this._user + "\r", this.PASSWORD_PROMPT);
                send(this.PASSWORD_PROMPT, this._userPw + "\r", "[#>]$");
            }
            catch (IllegalMISALStateException imse) {
                /* Fallback onto regular VTY logins. */
                send(this.PASSWORD_PROMPT, this._vtyPw + "\r", "[#>]$");
            }
            break;
        }

    }

    /** Become enabled on the connected IOS device.
     * @throws IllegalMISALStateException if enable mode cannot be reached
     * @throws IOException if an error occurs reading or writing the MISAL socket
     * @see #doDisable()
     * @see #doConfig()
     */
    public void doEnable() throws IllegalMISALStateException, IOException {
        switch (getState()) {
        case ENABLE_MODE:
            break;
        case DISABLE_MODE:
            send("enable\r", this.PASSWORD_PROMPT);
            send(this._enablePw + "\r", this.ENABLE_MODE);
            break;
        case CONFIG_MODE:
        case CONFIG_MODE_IF:
        case CONFIG_MODE_OTHER:
            send("end\r", this.ENABLE_MODE);
            break;
        default:
            throw new IllegalMISALStateException("Unable to get to enable mode");

        }
    }

    /** Become disabled on the connected IOS device.
     * @throws IllegalMISALStateException if the disabled prompt cannot be reached
     * @throws IOException if an error occurs reading or writing the MISAL socket
     * @see #doEnable()
     */
    public void doDisable() throws IllegalMISALStateException, IOException {
        switch (getState()) {
        case DISABLE_MODE:
            break;
        case ENABLE_MODE:
            send("disable\r", this.DISABLE_MODE);
            break;
        case CONFIG_MODE:
        case CONFIG_MODE_IF:
        case CONFIG_MODE_OTHER:
            send("end\r", this.ENABLE_MODE);
            this.doDisable();
            break;
        default:
            throw new IllegalMISALStateException("Unable to get to disable mode");
        }
    }

    /** Enter config mode on the connected IOS device.
     * @throws IllegalMISALStateException if config mode cannot be reached
     * @throws IOException if an error occurs reading or writing the MISAL socket
     * @see #doEnable()
     * @see #doDisable()
     */
    public void doConfig() throws IllegalMISALStateException, IOException {
        switch (getState()) {
        case DISABLE_MODE:
            this.doEnable();
            this.doConfig();
            break;
        case ENABLE_MODE:
            send("config term\r", this.CONFIG_MODE);
            break;
        case CONFIG_MODE:
            break;
        case CONFIG_MODE_IF:
        case CONFIG_MODE_OTHER:
            this.doEnable();
            this.doConfig();
            break;
        default:
            throw new IllegalMISALStateException("Unable to get to config mode.");
        }
    }

    /** Check to see if an IOS parser error occurred.
     * @return true if an IOS parser error occurred, false otherwise
     * @see #getLastErrorMessage()
     */
    public boolean errorOccurred() {
        Perl5Matcher matcher = new Perl5Matcher();
        Perl5Compiler compiler = new Perl5Compiler();
        Pattern pattern = null;
        try {
	    matcher.setMultiline(true);
            pattern = compiler.compile("^% (.*)$");
        }
        catch (MalformedPatternException mfpe) {}
        if (matcher.contains(getLastBuffer(), pattern)) {
            this.setLastErrorMessage(matcher.getMatch().group(1));
            return true;
        }
        return false;
    }

    /** Send data on the MISAL socket.  This overrides <CODE>send</CODE> from <CODE>MISAL</CODE>.
     * @param state integer representing the MISAL state to expect before sending data
     * @param data string representing the data to send
     * @param expect string representing the prompt to expect after sending the data (set to <CODE>null</CODE> to indicate a MISAL state integer will be provided)
     * @param expectState integer representing the state to expect after sending the data (set to 0 to indicate a string prompt will be provided)
     * @param wait number of seconds to wait for expected state
     * @throws IllegalMISALStateException if the given states could not be reached
     * @throws IOException if an error occurs reading or writing the MISAL socket
     * @see MISAL#send(int,String,String,int,int)
     */
    protected void send(int state, String data, String expect, int expectState, int wait) throws IllegalMISALStateException, IOException {
        boolean result = false;
        int currState = MISAL_STATE_UNKNOWN;
        byte[] b = null;
        if (wait == 0) wait = DEFAULT_RETRIES;
        if (state > 0) {
            for (int i = 1; i <= wait; i++) {
                currState = getState();
                debug("i = " + i + " and currState = " + currState);
                if (currState == state) break;
                try {
                    /* Sleep only a short time between state
                      	checks .*/
                    Thread.sleep(MISAL_SHORT_THREAD_SLEEP_INTERVAL);
                }
                catch (InterruptedException ie) {}
            }
            if (currState != state) {
                switch (state) {
                case ENABLE_MODE:
                    this.doEnable();
                    break;
                case DISABLE_MODE:
                    this.doDisable();
                    break;
                case CONFIG_MODE:
                    this.doConfig();
                    break;
                default:
                    throw new IllegalMISALStateException("Needed state " + state + ", but found state " + currState);
                }
            }
            /* This check is really redundant. */
            if (getState() != state) {
                throw new IllegalMISALStateException("Unable to set the desired state.");
            }
        }
        b = new byte[data.length()];
        b = data.getBytes();
        debug("Sending data " + data);
        getOutputStream().write(b, 0, b.length);
        getOutputStream().flush();
        /* When sending a command, set the state to unknown.  It might
           be better to think of this as pending until we can check
           the new state. */
        setState(MISAL_STATE_UNKNOWN);
        if (expect != null) {
            debug("Expecting \"" + expect + "\"");
            result = expect(expect, wait);
        }
        else {
            debug("Expecting state: " + expectState);
            result = expect(expectState, wait);
        }
        if (!result) {
            throw new IllegalMISALStateException("Unable to reach expected state.");
        }
    }

    /** Start the MISAL state watcher thread.  This method should never be called directly.  It is run automatically once a new <CODE>MISALCiscoIOS</CODE> class is instantiated.
     */
    public void run() {
        super.run();
    }

}
