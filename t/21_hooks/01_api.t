use strict;
use warnings;
use Test::More import => ['!pass'];

use Dancer ':syntax';

plan tests => 7;

my $cpt = 0;

ok( hook( 'before' => sub { $cpt += shift || 1 }), 'add a before filter');

my $app = Dancer::App->current->name;
is scalar @{ Dancer::Hook->get_hooks_for_app($app)->{before} }, 1, 'got one before filter';

my $hooks = Dancer::Hook->get_hooks_for('before');
is scalar @$hooks, 1, 'got one before filter';

Dancer::Hook->execute_hooks('before');
is $cpt, 1, 'execute hooks without args';

Dancer::Hook->execute_hooks( 'before', 2 );
is $cpt, 3, 'execute hooks with one arg';

my $hooks_listed = Dancer::Hook->get_hooks_name_list();
is scalar @$hooks_listed, 12;

my $hooks_listed_renderer = Dancer::Hook->get_hooks_name_list('Dancer::Renderer');
is scalar @$hooks_listed_renderer, 6;
