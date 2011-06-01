use Test::More tests => 5, import => ['!pass'];
use strict;
use warnings;
use Dancer ':syntax';
use Dancer::Template::Abstract;

my $a = Dancer::Template::Abstract->new;
eval { $a->render };
like $@, qr/render not implemented/, "cannot call abstract method render";
is $a->init, 1, "default init returns 1";

is $a->default_tmpl_ext, "tt";

$a = Dancer::Template::Abstract->new;
$a->config->{extension} = 'foo';
my $view = $a->_template_name('bar');
is $view, "bar.foo";

##
set 'engines/simple/extension' => 'bar';
$view = engine('template')->_template_name('bar');
is $view, "bar.bar";
