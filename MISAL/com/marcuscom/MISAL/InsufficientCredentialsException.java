package com.marcuscom.MISAL;

/**
 * <p>
 * A class to indicate that the credentials specified are not enough to
 * login to the device.
 * </p>
 * <p>&copy; 2001 MarcusCom, Inc.  All rights reserved.</p>
 *
 * @version	1.0, $Id$
 * @author 	Joe Clarke &lt;marcus@marcuscom.com&gt;
 * @see		MISAL
 */
public class InsufficientCredentialsException extends Exception {

    /**
     * Simply calls the corresponding constructor of its superclass.
     *
     * @param message A message indicating why the state desired was not
     * reached
     * @see		Exception
     * @since	MISAL1.0
     */
    public InsufficientCredentialsException(String message) {
        super(message);
    }
}

