package com.marcuscom.MISAL;

/**
 * <p>
 * A class to indicate that the desired state was not or could not be
 * reached.  When this exception is thrown, there is usually a problem in
 * the send/expect dialog with the socket.
 * </p>
 * <p>&copy; 2001-2004 MarcusCom, Inc.  All rights reserved.</p>
 *
 * @version	1.0, $Id$
 * @author 	Joe Clarke &lt;marcus@marcuscom.com&gt;
 * @see		MISAL
 */
public class IllegalMISALStateException extends IllegalArgumentException {

    /**
     * Simply calls the corresponding constructor of its superclass.
     *
     * @see		Exception
     * @since	MISAL1.0
     */
    public IllegalMISALStateException() {
        super();
    }

    /**
     * Simply calls the corresponding constructor of its superclass.
     *
     * @param message	A message indicating why the state desired was
     *			not reached
     * @see		Exception
     * @since		MISAL1.0
     */
    public IllegalMISALStateException(String message) {
        super(message);
    }
}

