package com.marcuscom.MISAL;

import java.io.*;
import java.net.*;
import com.oroinc.text.regex.MalformedPatternException;

public class MISALCiscoIOS extends MISAL {
	public static final int DISABLE_MODE = 1;
	public static final int ENABLE_MODE = 2;
	public static final int CONFIG_MODE = 3;
	public static final int CONFIG_MODE_IF = 4;
	public static final int CONFIG_MODE_OTHER = 5;
	public static final int VTY_PROMPT = 6;
	public static final int USER_PROMPT = 7;
	public static final int PASSWORD_PROMPT = 8;
	public static final int ENABLE_PROMPT = 9;

	protected static final int AUTH_UNKNOWN = 0;
	protected static final int AUTH_VTY = 1;
	protected static final int AUTH_USER = 2;
	protected static final int AUTH_VTY_ENABLE = 3;
	protected static final int AUTH_USER_ENABLE = 4;
	protected static final int AUTH_ENABLE_TACACS = 5;

	private String _vtyPw = null;
	private String _enablePw = null;
	private String _user = null;
	private String _userPw = null;

	public MISALCiscoIOS(Socket socket) throws SocketException, IOException {
		super(socket);

		/* Add Cisco-specific states */

		try {
			/* Standard disable prompt */
			addState(this.DISABLE_MODE, "> ?$"); 
			/* Standard enable prompt */
			addState(this.ENABLE_MODE, "[^\\)]# ?$"); 
			/* Vanilla config prompt */
			addState(this.CONFIG_MODE, "\\(config\\)# ?$");
			/* Config interface prompt */
			addState(this.CONFIG_MODE_IF, "\\(config-if\\)# ?$");
			/* Some other config prompt */
			addState(this.CONFIG_MODE_OTHER, "\\(config-[^i][^f]\\)# ?$");
			addState(this.VTY_PROMPT, "Password: ?$");
			addState(this.USER_PROMPT, "Username: ?$");
			addState(this.PASSWORD_PROMPT, "Password: ?$");
			addState(this.ENABLE_PROMPT, "Password: ?$");
		}
		catch (MalformedPatternException mfpe) {}
	}

	public void setEnablePassword(String enablePw) {
		this._enablePw = enablePw;
	}

	public void setUsername(String username) {
		this._user = username;
	}

	public void setVtyPassword(String vtyPw) {
		this._vtyPw = vtyPw;
	}

	public void setUserPassword(String userPw) {
		this._userPw = userPw;
	}

	public void setUserPrompt(String prompt) throws MalformedPatternException {
		addState(this.USER_PROMPT, prompt);
	}

	public void setPasswordPrompt(String prompt) throws MalformedPatternException {
		addState(this.PASSWORD_PROMPT, prompt);
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

	public void login() throws InsufficientCredentialsException, IllegalMISALStateException, IOException {
		if (getState() != MISAL_STATE_INITIAL) {
			return;
		}
		switch (this.getAuthScheme(this.DISABLE_MODE)) {
			case AUTH_VTY:
				/* Expect a Password: prompt */
				send(this.VTY_PROMPT, this._vtyPw, this.DISABLE_MODE);
				/* If we don't get what we expect, throw
				   the IllegalMISALStateException. */
				break;
			case AUTH_USER:
				try {
					/* Expect either ENABLE or DISABLE MODE
					   as we could be using enable TACACS */
					send(this.USER_PROMPT, this._user, this.PASSWORD_PROMPT);
					send(this.PASSWORD_PROMPT, this._userPw, "[#>] ?$");
				}
				catch (IllegalMISALStateException imse) {
					/* Fallback onto regular VTY logins. */
					send(this.VTY_PROMPT, this._vtyPw, this.DISABLE_MODE);
				}
				break;

		}

	}

	public void doEnable() throws IllegalMISALStateException, IOException {
		switch (getState()) {
			case ENABLE_MODE:
				break;
			case DISABLE_MODE:
				send("enable\r", this.ENABLE_PROMPT);
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

	public void send(int state, String data, int expectState) throws IllegalMISALStateException, IOException {
		this.send(state, data, null, expectState, 0);
	}

	public void send(String data, String expect) throws IllegalMISALStateException, IOException {
		this.send(MISAL_STATE_UNKNOWN, data, expect, 0, 0);
	}

	public void send(String data, int expectState) throws IllegalMISALStateException, IOException {
		this.send(MISAL_STATE_UNKNOWN, data, null, expectState, 0);
	}

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
}
