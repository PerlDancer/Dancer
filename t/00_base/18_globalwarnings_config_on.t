#!/usr/bin/perl
use warnings;
use strict;
use Test::More import => ['!pass'];
use Dancer;

set global_warnings => 1;
is $^W, 1, "Global warnings turned on through global_warnings";

set global_warnings => 0;
is $^W, 0, "Global warnings turned off through global_warnings";

set import_warnings => 1;
is $^W, 1, "Global warnings turned on through import_warnings";

set import_warnings => 0;
is $^W, 0, "Global warnings turned off through import_warnings";

done_testing();
