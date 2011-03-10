#!/usr/bin/env perl

use Test::More import => ['!pass'], tests => 3;

use strict;
use warnings;

use Dancer;

my $CLASS = "Dancer::Logger::Capture";
use_ok $CLASS;

note "basic capture"; {
    my $logger = $CLASS->new;

    $logger->warning("Danger!  Warning!  Danger!");
    $logger->debug("I like pie.");

    my $trap = $CLASS->trap;
    is_deeply $trap->read, [
        { level => "warning",   message => "Danger!  Warning!  Danger!" },
        { level => "debug",     message => "I like pie.", }
    ];

    is_deeply $trap->read, [],  "read clears the trap";
}
