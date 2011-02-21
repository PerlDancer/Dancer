use strict;
use warnings;
use Test::More import => ['!pass'];

use Dancer ':syntax';

plan tests => 2;

ok( hook ('before', sub { 1 }), 'add a before filter' );
my $app = Dancer::App->current;
is scalar @{$app->registry->hooks->{before}}, 1, 'got one before filter';
