use strict;
use warnings;
use Test::More import => ['!pass'];

use Dancer ':syntax';

plan tests => 10;

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


sub exception (&) { eval { $_[0]->() }; return $@ }

ok(
    hook('before' => sub { $cpt += 2; undef $_ }),
    'add a bad filter that manipulates $_'
);

$cpt = 0;
is(exception { Dancer::Factory::Hook->instance->execute_hooks('before', 5) },
    '', 'execute_hooks() lives with bad hooks');
is($cpt, 7, 'execute hooks with one arg, ok result');

$cpt = 0;
is(exception { Dancer::Factory::Hook->instance->execute_hooks('before', 8) },
    '', 'execute_hooks() lives second time with bad hooks');
is($cpt, 10, 'execute hooks with one arg, ok result');
