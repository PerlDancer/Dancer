package Dancer::Exceptions;

use strict;
use vars qw/$VERSION/;

$VERSION = 0.1;

my %e;

BEGIN {
	%e = (
		'Dancer::Exception::Halt' => {
			description => 'Exception to halt and exit the execution of a route.',
			alias => 'halt',
		},
		'Dancer::Exception::Pass' => {
			description => 'Passes the route evaluation to the next route block.',
			alias => 'pass_exception',
		}
	);
}

use Exception::Class (%e);

sub import {
	my ($class, %args) = @_;
	
	my $caller = caller;
	
	while(my ($c, $v) = each %e) {
		{
			no strict 'refs';
			*{"${caller}::".$v->{alias}} = \&{$v->{alias}};
		}
	}	
}

1;