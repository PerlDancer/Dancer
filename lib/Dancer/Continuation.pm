package Dancer::Continuation;

use strict;
use warnings;
use Carp;

sub new {
    my $class = shift;
    bless { @_ }, $class;
}

sub throw { die shift }

sub rethrow { die shift }

1;
