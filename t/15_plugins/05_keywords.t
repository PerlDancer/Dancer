use strict;
use warnings;
use Test::More import => ['!pass'];

use Dancer ':syntax';
use Dancer::Plugin;

eval {register dance => sub {1};};
ok $@;
like $@, qr/You can't use dance, this is a reserved keyword/;

done_testing;

