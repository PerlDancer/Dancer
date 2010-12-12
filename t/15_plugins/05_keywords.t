use strict;
use warnings;
use Test::More import => ['!pass'];

plan tests => 6;

use Dancer ':syntax';
use Dancer::Plugin;

eval {register dance => sub {1};};
ok $@;
like $@, qr/You can't use 'dance', this is a reserved keyword/;

{
    local @Dancer::EXPORT = (@Dancer::EXPORT, '&frobnicator');

    eval {register 'frobnicator' => sub {1};};
    ok $@;
    like $@, qr/You can't use 'frobnicator', this is a reserved keyword/;

}

eval {register '1function' => sub {1};};
ok $@;
like $@, qr/You can't use '1function', it is an invalid name/;
