package Dancer::Continuation::Halted;

use strict;
use warnings;
use Carp;

use base qw(Dancer::Continuation);

sub new { bless {}, shift }

sub throw { die shift }

1;
