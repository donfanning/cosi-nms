#-
# Copyright (c) 2001 Joe Clarke <marcus@marcuscom.com>
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
# 1. Redistributions of source code must retain the above copyright
#    notice, this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright
#    notice, this list of conditions and the following disclaimer in the
#    documentation and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS'' AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
# OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
# HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
# LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
# OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
# SUCH DAMAGE.
#
# $Id$
#

package Rules;

use strict;
use Carp;

use vars qw($linenum);

# Indicate the current linenumber.
$linenum = 0;

sub LOCK_SH { 1 }
sub LOCK_EX { 2 }
sub LOCK_NB { 4 }
sub LOCK_UN { 8 }

# These are used iff both a rule action doesn't specify community strings,
# and the global community string variables are not defined.
use constant READ_COMM  => 'public';
use constant WRITE_COMM => 'private';

sub new {

    # The Rules constructor takes a reference to a filename as an argument.
    # This file contains the rules to be read.
    my ( $that, @args ) = @_;
    my $class = ref($that) || $that;

    if ( scalar(@args) != 1 ) {
        croak "Rules: Insufficient arguments passed to constructor";
    }

    my $self = {
        rulesFile    => $args[0],
        fh           => undef,
        error        => undef,
        rules        => {},
        rulesIndex   => [],
        vars         => {},
        actions      => {},
        actionsIndex => [],
    };

    bless( $self, $class );
    $self;
}

sub rules_file {
    my $self = shift;
    return $self->{rulesFile};
}

sub error {
    my $self = shift;
    if (@_) { $self->{error} = shift; }
    return $self->{error};
}

sub _fh {
    my $self  = shift;
    my $class = ref $self;
    croak "Attempt to call private method" if ( $class ne __PACKAGE__ );
    if (@_) { $self->{fh} = shift; }
    return $self->{fh};
}

sub actions {
    my $self = shift;
    if (@_) {
        my %args = @_;
        foreach ( keys %args ) {
            if ( !$self->{actions}->{$_} ) {
                $self->{actions}->{$_} = $args{$_};
            }
            else {
                $self->error(
                    "Cannot add duplicate action, $_, at line $linenum");
                return;
            }
        }
    }
    return $self->{actions};
}

sub actions_index {
    my $self = shift;
    if (@_) {
        my $action = shift;
        push @{ $self->{actionsIndex} }, $action;
    }
    return $self->{actionsIndex};
}

sub rules {
    my $self = shift;
    if (@_) {
        my %args = @_;
        foreach ( keys %args ) {
            if ( !$self->{rules}->{$_} ) {
                $self->{rules}->{$_} = $args{$_};
            }
            else {
                $self->error("Cannot add duplicate rule, $_, at line $linenum");
                return;
            }
        }
    }
    return $self->{rules};
}

sub rules_index {
    my $self = shift;
    if (@_) {
        my $rule = shift;
        push @{ $self->{rulesIndex} }, $rule;
    }
    return $self->{rulesIndex};
}

sub vars {
    my $self = shift;
    if (@_) {
        my %args = @_;
        foreach ( keys %args ) {
            $self->{vars}->{$_} = $args{$_};
        }
    }
    return $self->{vars};
}

sub _checkRulesActions {
    my $self  = shift;
    my $class = ref $self;
    croak "Attempt to call private method" if ( $class ne __PACKAGE__ );
    my $rules   = $self->rules();
    my $actions = $self->actions();

    foreach ( keys %{$rules} ) {
        if ( !$actions->{$_} ) {
            $self->error("Rule $_ has no corresponding action");
            return;
        }
    }

    1;
}

sub _checkForComms {
    my $self  = shift;
    my $class = ref $self;
    croak "Attempt to call private method" if ( $class ne __PACKAGE__ );
    my ( $readComm, $writeComm );

    $readComm  = 0;
    $writeComm = 0;

    my $vars = $self->vars();

    foreach ( keys %{$vars} ) {
        if ( $_ eq "READ_COMM" && $vars->{$_} ) {
            $readComm = 1;
        }
        if ( $_ eq "WRITE_COMM" && $vars->{$_} ) {
            $writeComm = 1;
        }
    }

    if ( !$readComm ) {
        $self->vars( 'READ_COMM' => READ_COMM );
    }
    if ( !$writeComm ) {
        $self->vars( 'WRITE_COMM' => WRITE_COMM );
    }

    1;
}

sub readRules {
    my $self = shift;
    my ( $line, $rules_file, $result );

    $rules_file = $self->rules_file();

    unless ( open( RULES, $rules_file ) ) {
        $self->error("Cannot open $rules_file: $!");
        return;
    }
    flock( RULES, LOCK_SH );

    $self->_fh( \*RULES );
    $line   = $self->_readLine();
    $result = 1;
    while ( $line && $result ) {
        SWITCH: {
            $result = $self->_parseComment(), last SWITCH if $line =~ m|^/\*|;
            $result = $self->_parseRule($line), last SWITCH
              if $line =~ /^rule\s/;
            $result = $self->_parseVar($line), last SWITCH if $line =~ /^var\s/;
            $result = $self->_parseAction($line), last SWITCH
              if $line =~ /^action\s/;
            $line = -1, last SWITCH;
        }

        if ( $line == -1 ) {
            $self->error("Error parsing config file at line $linenum");
            return;
        }
        $line = $self->_readLine();
    }
    close(RULES);
    $self->_fh(undef);

    if ($result) {

        # Verify we have global catchall community strings defined.
        $self->_checkForComms();
        if ( !$self->_checkRulesActions() ) {
            return;
        }
    }

    $result;
}

sub _parseRule {
    my $self  = shift;
    my $class = ref $self;
    croak "Attempt to call private method" if ( $class ne __PACKAGE__ );
    my $line = shift;
    my ( $rec, $name, $equal, $lcurlyBrace, $hName, $hValue, $status );
    my ($i);

    $i = 0;

    $rec = {
        name => '',
    };

    $line =~ s/\s+/ /g;
    $line =~ s/^rule //;
    $line =~ s|//.*||;
    ( $name, $equal, $lcurlyBrace ) = ( $line =~ /(^[\d\w]+) ?(=) ?(\{$)/ )
      or $status = -1;
    if ( $status == -1 ) {

        $self->error("Syntax error parsing rule at line $linenum");
        return;
    }
    if ( !$self->rules( $name => $rec ) ) {
        return;
    }
    $self->rules_index($name);
    $line = $self->_readLine();

    while ( $line && $line !~ /^\}\;?$/ ) {
        if ( $line =~ m|^//| ) {
            $line = $self->_readLine();
            next;
        }

        if ( $line =~ m|^/\*| ) {
            $self->_parseComment();
            $line = $self->_readLine();
            next;
        }
        ( $hName, $hValue ) = split ( /\s*=\s*/, $line, 2 );

        if ( $hName eq "" || $hValue eq "" ) {
            $self->error("Syntax error parsing rule at line $linenum");
            return;
        }
        $hName =~ tr/[A-Z]/[a-z]/;

        if ( !defined( $rec->{$hName} ) ) {
            $self->error(
"Syntax error parsing rule at line $linenum.  lvalue \"$hName\" is undefined"
            );
            return;
        }
        elsif ( $rec->{$hName} ne '' ) {

            $self->error(
"Syntax error parsing rule at line $linenum.  lvalue \"$hName\" is used more than once"
            );
            return;
        }

        # Check the regexp syntax.
        if ( !$self->_checkExpr( $rec->{name}, $name ) ) {
            return;
        }
        $hValue =~ s/\;$//;
        $rec->{$hName} = $hValue;
        $line = $self->_readLine();
    }

    if ( !$line ) {
        $self->error("Expected } or }; but found EOF");
        return;
    }

    1;
}

sub _parseComment {
    my $self  = shift;
    my $class = ref $self;
    croak "Attempt to call private method" if ( $class ne __PACKAGE__ );
    my ($line);

    $line = $self->_readLine();

    while ( $line && $line !~ m|\*/$| ) {
        $line = $self->_readLine();
    }
    if ( !$line ) {
        $self->error("Expected */ but found EOF");
        return;
    }

    1;
}

sub _parseVar {
    my $self  = shift;
    my $class = ref $self;
    croak "Attempt to call private method" if ( $class ne __PACKAGE__ );
    my $line = shift;
    my ( $name, $value );

    $line =~ s/\s+/ /g;
    $line =~ s/^var //;
    $line =~ s|//.*||;

    ( $name, $value ) = split ( /\s*=\s*/, $line, 2 );
    if ( $name eq "" || $value eq "" ) {
        $self->error("Syntax error parsing variable at line $linenum");
        return;
    }
    $name  =~ tr/[a-z]/[A-Z]/;
    $value =~ s/\;$//;           # take off trailing semi-colon if any
    $self->vars( $name => $value );

    1;
}

sub _parseAction {
    my $self  = shift;
    my $class = ref $self;
    croak "Attempt to call private method" if ( $class ne __PACKAGE__ );
    my $line = shift;
    my ( $rec, $name, $equal, $lcurlyBrace, $hName, $hValue, $status );
    my ($i);

    $i = 0;

    $rec = {
        readcomm  => '',
        writecomm => '',
        timeout   => '',
        retries   => '',
    };

    $line =~ s/\s+/ /g;
    $line =~ s/^action //;
    $line =~ s|//.*||;
    ( $name, $equal, $lcurlyBrace ) = ( $line =~ /(^[\d\w]+) ?(=) ?(\{$)/ )
      or $status = -1;
    if ( $status == -1 ) {

        $self->error("Syntax error parsing rule at line $linenum");
        return;
    }
    if ( !$self->actions( $name => $rec ) ) {
        return;
    }
    $self->actions_index($name);
    $line = $self->_readLine();

    while ( $line && $line !~ /^\}\;?$/ ) {
        if ( $line =~ m|^//| ) {
            $line = $self->_readLine();
            next;
        }

        if ( $line =~ m|^/\*| ) {
            $self->_parseComment();
            $line = $self->_readLine();
            next;
        }
        ( $hName, $hValue ) = split ( /\s*=\s*/, $line, 2 );

        if ( $hName eq "" || $hValue eq "" ) {
            $self->error("Syntax error parsing rule at line $linenum");
            return;
        }
        $hName =~ tr/[A-Z]/[a-z]/;

        if ( !defined( $rec->{$hName} ) ) {
            $self->error(
"Syntax error parsing rule at line $linenum.  lvalue \"$hName\" is undefined"
            );
            return;
        }
        elsif ( $rec->{$hName} ne '' ) {

            $self->error(
"Syntax error parsing rule at line $linenum.  lvalue \"$hName\" is used more than once"
            );
            return;
        }
        $hValue =~ s/\;$//;
        $rec->{$hName} = $hValue;
        $line = $self->_readLine();
    }

    if ( !$line ) {
        $self->error("Expected } or }; but found EOF");
        return;
    }

    1;
}

sub _readLine {
    my $self  = shift;
    my $class = ref $self;
    croak "Attempt to call private method" if ( $class ne __PACKAGE__ );
    my ($line);

    my $fh = $self->_fh();
    $line = <$fh>;

    return $line if !$line;

    $linenum++;
    chomp $line;
    $line =~ s|//.*||;
    $line =~ s/^\s+//;
    $line =~ s/\s+$//;

    return $line if length($line);
    $self->_readLine();
}

sub _checkExpr {
    my $self  = shift;
    my $class = ref $self;
    croak "Attempt to call private method" if ( $class ne __PACKAGE__ );
    my ( $expr, $rule ) = @_;
    my ($status);

    eval { 'sieve' =~ /$expr/, 1 } or $status = -1;
    if ( $status == -1 ) {
        $self->error("Syntax error in rule $rule: bad pattern: $@");
        return;
    }

    1;
}

1;
