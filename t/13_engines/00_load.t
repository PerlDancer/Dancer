use Test::More tests => 3;

use_ok 'Dancer::Engine';

eval {
    Dancer::Engine->build();
};
ok $@;
like $@, qr/cannot build engine/;
