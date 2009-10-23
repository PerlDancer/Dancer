use Test::More tests => 5;

use strict;
use warnings;

use Dancer::Config 'setting';

BEGIN { use_ok 'Dancer::Template' }

is( Dancer::Template->engine, undef,
    "Dancer::Template->engine is undefined");

ok(Dancer::Template->init, "template init with undef setting");

setting template => 'FOOOBAR';
eval { Dancer::Template->init };
like $@, qr/unknown template engine/, "cannot load unknown template engine";

setting template => 'simple';
ok(Dancer::Template->init, "template init with 'simple' setting");
