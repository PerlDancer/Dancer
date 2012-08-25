use Test::More import => ['!pass'];

use strict;
use warnings;
use Dancer::ModuleLoader;
use Dancer;

plan skip_all => "Template needed" 
    unless Dancer::ModuleLoader->load('Template');

plan tests => 6;

use_ok 'Dancer::Template';

ok(Dancer::Template->init, "template init with undef setting");

eval { setting template => 'FOOOBAR' };
like $@, qr/unable to load template engine/, "cannot load unknown template engine";

setting template => 'simple';
ok(Dancer::Template->init, "template init with 'simple' setting");

is(ref(Dancer::Template->engine), 'Dancer::Template::Simple',
    "template engine is Simple");


set template => 'template_toolkit';
is(ref(Dancer::Template->engine), 'Dancer::Template::TemplateToolkit',
    "template engine is TT");

