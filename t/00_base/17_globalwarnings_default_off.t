#!/usr/bin/perl
use warnings;
use strict;
use Test::More import => ['!pass'];
use Dancer;

is $^W, 0, "Global warnings off by default.";

done_testing;
