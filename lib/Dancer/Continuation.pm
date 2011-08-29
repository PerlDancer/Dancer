package Dancer::Continuation;

use strict;
use warnings;
use Carp;

sub new { bless {}, shift }

sub throw { die shift }

sub rethrow { die shift }

1;
