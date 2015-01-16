package Dancer::Continuation;
# ABSTRACT: Continuation exception (internal exception) for Dancer

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
