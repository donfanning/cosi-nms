package com.marcuscom.MISAL;

/**
 * <p>
 * A class to indicate an error has occurred when trying to define a new
 * MISAL state.  When this exception is thrown, it usually indicates the
 * prompt string is a malformed Perl regular expression.  The message will
 * have more details.
 * </p>
 * <p>&copy; 2001 MarcusCom, Inc.  All rights reserved.</p>
 *
 * @version	1.0, $Id$
 * @author 	Joe Clarke &lt;marcus@marcuscom.com&gt;
 * @see		MISAL
 */
public class MalformedMISALStateException extends Exception {
    /**
     * Simply calls the corresponding constructor of its superclass.
     *
     * @see		Exception
     * @since	MISAL1.0
     */
    public MalformedMISALStateException() {
        super();
    }

    /**
     * Simply calls the corresponding constructor of its superclass.
     *
     * @param message	A message indicating why there is an error in
     *			the state
     * @see		Exception
     * @since		MISAL1.0
     */
    public MalformedMISALStateException(String message) {
        super(message);
    }
}
