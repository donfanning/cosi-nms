package SAA::CGI::Error;

use strict;
require 5.002;

use vars qw(@ISA @EXPORT);
use Exporter;
@ISA = qw(Exporter);
@EXPORT = qw(return_error);

sub return_error {
	my ($q, $reason) = @_;

	print $q->header("text/html");
	print $q->start_html("SAA Configurator Error");
	print $q->h1("SAA Configurator Error");
	print $q->p("The SAA Configurator encountered the following error: ");
	print $q->p($q->i($reason));
	print $q->end_html;

	exit(0);
}

1;
