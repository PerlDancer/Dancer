use strict;
use warnings;
use Test::More import => ['!pass'];

plan tests => 2;

use Dancer ':syntax';
use Dancer::Plugin;

eval {register dance => sub {1};};
ok $@;
like $@, qr/You can't use dance, this is a reserved keyword/;
