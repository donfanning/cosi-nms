/*-
 * Copyright (c) 2002 Joe Marcus Clarke <marcus@marcuscom.com>
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

package com.marcuscom.deesv;

import java.util.*;
import java.io.*;

public class DEEsvContainer {
    protected String title = null;
    protected Vector order = null;
    protected Vector data = null;

    public DEEsvContainer(String title) {
        this.title = title;
        this.order = new Vector();
        this.data = new Vector();
    }

    public void addOrder(Object o) {
        this.order.addElement(o);
    }

    public void addData(Object o) {
        this.data.addElement(o);
    }

    public boolean orderContains(Object o) {
        return this.order.contains(o);
    }

    public void print(PrintStream ps, char separator) throws IOException {
        this.writeHeader(ps, separator);
        this.writeData(ps, separator);
    }

    protected void writeHeader(PrintStream ps, char separator)
    throws IOException {

        Enumeration e = order.elements();

        if (!e.hasMoreElements()) return;

        ps.println(title);
        for (int i = 0; i < 77; i++) {
            ps.print('-');
            ps.flush();
        }
        ps.println("");
        while (e.hasMoreElements()) {
            ps.print((String)e.nextElement());
            ps.flush();
            if (e.hasMoreElements()) {
                ps.print(separator);
                ps.flush();
            }
        }
        ps.println("");
        for (int i = 0; i < 77; i++) {
            ps.print('-');
            ps.flush();
        }
        ps.println("");
    }

    protected void writeData(PrintStream ps, char separator)
    throws IOException {

        if (data.size() == 0) return;

        for (int i = 0; i < data.size(); i++) {
            Hashtable h = (Hashtable)data.elementAt(i);

            if (h.size() == 0) continue;

            Enumeration e = order.elements();
            while (e.hasMoreElements()) {
                String datum = (String)h.get(e.nextElement());
                if (datum != null && !datum.equals("null")) {
                    datum = datum.trim();
                    datum = datum.replace('\n', ' ');
                    datum = datum.replace('\r', ' ');
                    if (datum.indexOf(separator) >= 0 &&
                            !datum.startsWith("\"") && !datum.endsWith("\"")) {
                        StringBuffer sb = new StringBuffer(datum);
                        sb = sb.append("\"");
                        sb = sb.insert(0, "\"");
                        datum = sb.toString();
                    }
                }
                else {
                    datum = "";
                }
                ps.print(datum);
                ps.flush();
                if (e.hasMoreElements()) {
                    ps.print(separator);
                    ps.flush();
                }
            }
            ps.println("");
        }
        ps.print("\n\n\n");
        ps.flush();
    }
}
