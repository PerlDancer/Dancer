use Test::More import => ['!pass'];

use strict;
use warnings;
use Dancer::ModuleLoader;
use Dancer;

plan skip_all => "Template needed" 
    unless Dancer::ModuleLoader->load('Template');

plan tests => 8;

use_ok 'Dancer::Template';

ok(Dancer::Template->init, "template init with undef setting");

eval { setting template => 'FOOOBAR' };
like $@, qr/unknown template engine/, "cannot load unknown template engine";

# Dancer::Template::Simple should trigger a warning
{
    my $warn;
    local $SIG{__WARN__} = sub { $warn = $_[0] };

    setting template => 'simple';
    ok(Dancer::Template->init, "template init with 'simple' setting");
    like $warn, qr/Dancer::Template::Simple is deprecated, use another engine/, 
        "Dancer::Template::Simple deprecated, warning triggered";
}

is(ref(Dancer::Template->engine), 'Dancer::Template::TemplateToolkit',
    "template engine is Simple");


ok(setting(template => 'template_toolkit'), "template init with 'toolkit' setting");
is(ref(Dancer::Template->engine), 'Dancer::Template::TemplateToolkit',
    "template engine is TT");

