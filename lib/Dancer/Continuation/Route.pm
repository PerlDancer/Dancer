package Dancer::Continuation::Route;

use strict;
use warnings;
use Carp;

use base qw(Dancer::Continuation);

# A Dancer::Continuation::Route is a continuation exception, that is caught as
# route execution level (see Dancer::Route::run). It may store a return_value, that
# will be recovered from the continuation catcher, and stored as the returning
# content.

sub return_value { $#_ ? $_[0]->{return_value} = $_[1] : $_[0]->{return_value} }


1;
