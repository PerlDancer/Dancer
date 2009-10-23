use Test::More;

use strict;
use warnings;
use Dancer::ModuleLoader;
use Dancer::Config 'setting';

plan skip_all => "Template needed" 
    unless Dancer::ModuleLoader->load('Template');

plan tests => 8;

use_ok 'Dancer::Template';

is( Dancer::Template->engine, undef,
    "Dancer::Template->engine is undefined");

ok(Dancer::Template->init, "template init with undef setting");

setting template => 'FOOOBAR';
eval { Dancer::Template->init };
like $@, qr/unknown template engine/, "cannot load unknown template engine";

setting template => 'simple';
ok(Dancer::Template->init, "template init with 'simple' setting");

is(ref(Dancer::Template->engine), 'Dancer::Template::Simple',
    "template engine is Simple");

setting template => 'template_toolkit';
ok(Dancer::Template->init, "template init with 'toolkit' setting");
is(ref(Dancer::Template->engine), 'Dancer::Template::TemplateToolkit',
    "template engine is TT");

