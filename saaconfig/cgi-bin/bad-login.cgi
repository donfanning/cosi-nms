#!/usr/bin/perl -wT

use strict;
require 5.002;
use CGI;
use CGI::Carp qw(fatalsToBrowser);
use vars qw($DEFAULT_MSG);

$| = 1;

$DEFAULT_MSG = 'Invalid Login';

my $q = new CGI();

my $msg = $DEFAULT_MSG;
if ( $q->param("msg") ) {
    $msg = $q->param("msg");
}

print <<"HTML";
<!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">

<html>
  <head>
    <meta name="generator" content="HTML Tidy, see www.w3.org">
<script type="text/javascript" language="JavaScript" src=
"/funcstion.js">
</script>
<script type="text/javascript" language="JavaScript">
<!-- //

function verify(f) {
    var user = f.elements.form_user.value;
    if (isBlank(user)) {
        alert("Please enter your username.");
        return false;
    }
    return true;
}

// -->
</script>

    <title>Service Assurance Agent Configurator</title>
  </head>

  <body bgcolor="#FFFFFF">
    <form method="POST" action="/cgi-bin/login.cgi" onsubmit=
    " return verify(this) ">
      &nbsp;<br>
       &nbsp;<br>
       &nbsp; 

      <center>
        <h1>Service Assurance Agent Configurator</h1>

        <p>&nbsp;</p>
        <font size="+2"><b>Please Login</b></font> 

        <p>&nbsp;</p>

        <table cols="2" width="25%">
          <tr>
            <td bgcolor="#4A708B"><font color=
            "#FFFFFF"><b>Username:</b></font></td>

            <td bgcolor="#DCDCDC"><input type="TEXT" name=
            "form_user"></td>
          </tr>

          <tr>
            <td bgcolor="#4A708B"><font color=
            "#FFFFFF"><b>Password:</b></font></td>

            <td bgcolor="#DCDCDC"><input type="PASSWORD" name=
            "form_pass"></td>
          </tr>
        </table>

		<p><font color="#FF0000" size="-1">$msg</font></p>

        <p><input type="SUBMIT" value="Login"></p>
      </center>
    </form>
  </body>
</html>
HTML

