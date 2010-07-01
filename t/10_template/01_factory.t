use Test::More import => ['!pass'];

use strict;
use warnings;
use Dancer::ModuleLoader;
use Dancer;

plan skip_all => "Template needed" 
    unless Dancer::ModuleLoader->load('Template');

plan tests => 7;

use_ok 'Dancer::Template';

ok(Dancer::Template->init, "template init with undef setting");

eval { setting template => 'FOOOBAR' };
like $@, qr/unknown template engine/, "cannot load unknown template engine";

setting template => 'simple';
ok(Dancer::Template->init, "template init with 'simple' setting");

is(ref(Dancer::Template->engine), 'Dancer::Template::Simple',
    "template engine is Simple");


ok(setting(template => 'template_toolkit'), "template init with 'toolkit' setting");
is(ref(Dancer::Template->engine), 'Dancer::Template::TemplateToolkit',
    "template engine is TT");

