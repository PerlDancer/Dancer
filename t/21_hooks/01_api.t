use strict;
use warnings;
use Test::More import => ['!pass'];

use Dancer ':syntax';

plan tests => 5;

my $cpt = 0;

ok(
    hook
      'before' => sub { my $i = shift; $i ? $cpt += $i : $cpt++ },
    'add a before filter'
);

my $app = Dancer::App->current;
is scalar @{$app->registry->hooks->{before}}, 1, 'got one before filter';

my $hooks = Dancer::App->get_hooks_for('before');
is scalar @$hooks, 1, 'got one before filter';

Dancer::App->execute_hooks('before');
is $cpt, 1, 'execute hooks without args';

Dancer::App->execute_hooks('before', 2);
is $cpt, 3, 'execute hooks with one arg';
