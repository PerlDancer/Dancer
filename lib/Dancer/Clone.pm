package Dancer::Clone;

use strict;
use warnings;

sub clone {
    my ($data) = @_;
    my $clone;
    return $data unless ref($data);

    if (ref($data) eq 'ARRAY') {
        $clone = [];
        for my $e (@$data) {
            push @$clone, clone($e);
        }
    }
    elsif (ref($data) eq 'HASH') {
        $clone = {};
        for my $k (keys %$data) {
            $clone->{$k} = clone($data->{$k});
        }
    }
    else {
        $clone = $data;
    }
    return $clone;
}

1;
