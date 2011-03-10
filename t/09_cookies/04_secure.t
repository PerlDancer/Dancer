#!/usr/bin/env perl

use strict;
use warnings;
use Test::More tests => 5;

my $CLASS = 'Dancer::Cookie';
use_ok $CLASS;

note "not secure"; {
    my $cookie = $CLASS->new(
        name    => "foo",
        value   => "bar",
    );

    ok !$cookie->secure;
    my @headers = split /;\s+/, $cookie->to_header;
    ok !grep { lc $_ eq lc "secure" } @headers;
}


note "secure cookie"; {
    my $cookie = $CLASS->new(
        name    => "foo",
        value   => "bar",
        secure  => 1
    );

    ok $cookie->secure;
    my @headers = split /;\s+/, $cookie->to_header;
    ok grep { lc $_ eq lc "secure" } @headers;
}
