use Test::More tests => 5;

use_ok 'Dancer::Engine';

eval {
    Dancer::Engine->build();
};
ok $@;
like $@, qr/cannot build engine/;

eval {
    Dancer::Engine->build(undef, "name");
};
ok $@;
like $@, qr/cannot build engine/;
