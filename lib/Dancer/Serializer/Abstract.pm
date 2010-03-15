package Dancer::Serializer::Abstract;

use strict;
use warnings;
use base 'Dancer::Engine';

sub serialize {
    die "must be implemented";
}

sub deserialize {
    die "must be implemented";
}
1;
