use Test::More tests => 2;
use strict;
use warnings;

use Dancer::Template::Abstract;

my $a = Dancer::Template::Abstract->new;
eval { $a->render };
like $@, qr/render not implemented/, "cannot call abstract method render";
is $a->init, 1, "default init returns 1";
