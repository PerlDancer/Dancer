package Dancer::Route::Registry;
use strict;
use warnings;

use base 'Dancer::Object';

sub init {
    my ($self) = @_;
    $self->{routes} = {};
    $self->{before_filters} = [];
}

my $_registry;

sub get { $_registry }
sub set { $_registry = $_[1] }
sub reset { $_registry = Dancer::Route::Registry->new }



1;
