use Test::More tests => 4, import => ['!pass'];
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
my @views = $a->_template_name('bar');
is_deeply \@views, ["bar", "bar.foo" ];
