use strict;
use warnings;
use Test::More import => ['!pass'];

use Dancer ':syntax';

plan tests => 3;

ok( hook ('before', sub { 1 }), 'add a before filter' );
my $app = Dancer::App->current;
is scalar @{$app->registry->hooks->{before}}, 1, 'got one before filter';

my $hooks = Dancer::App->get_hooks_for('before');
is scalar @$hooks, 1, 'got one before filter';
