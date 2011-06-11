use Test::More 'no_plan', import => ['!pass'];

use Dancer ':syntax';
use Dancer::Test;

my $routes = path('t', '06_helpers', 'routes.pl');

ok( -f $routes, "file routes is found");
load $routes;

response_status_is [GET => '/foo'] => 200;
