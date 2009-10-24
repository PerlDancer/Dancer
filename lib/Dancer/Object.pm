package Dancer::Object;

use strict;
use warnings;

sub new {
    my ($class, %args) = @_;
    my $self = \%args;
    bless $self, $class;
    $self->init;
    return $self;
}

sub init { 1 }

1;
