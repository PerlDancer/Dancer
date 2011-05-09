use strict;
use warnings;
use Test::More import => ['!pass'];

use Dancer ':syntax';

plan tests => 5;

my $cpt = 0;

ok( hook( 'before' => sub { $cpt += shift || 1 }), 'add a before filter');

my $app = Dancer::App->current->name;
is scalar @{ Dancer::Factory::Hook->instance->get_hooks_for('before') }, 1, 'got one before filter';

my $hooks = Dancer::Factory::Hook->instance->get_hooks_for('before');
is scalar @$hooks, 1, 'got one before filter';

Dancer::Factory::Hook->instance->execute_hooks('before');
is $cpt, 1, 'execute hooks without args';

Dancer::Factory::Hook->instance->execute_hooks( 'before', 2 );
is $cpt, 3, 'execute hooks with one arg';
