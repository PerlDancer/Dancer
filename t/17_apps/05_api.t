use strict;
use warnings;
use Test::More;

use Dancer::App;

plan tests => 7;

ok my $app = Dancer::App->new();

ok $app->app_exists('main');
ok !$app->app_exists('foo');

ok my $current_app = $app->get('main');
isa_ok $current_app, 'Dancer::App';

my @routes = $app->routes('get');
is scalar @routes, 0;

$app->registry->universal_add('get', '/', sub{1});
@routes = $app->routes('get');
is scalar @routes, 1;
