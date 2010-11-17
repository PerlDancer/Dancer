use Test::More 'no_plan', import => ['!pass'];

use Dancer ':syntax';
use File::Spec;
use lib File::Spec->catdir( 't', 'lib' );
use TestUtils;

my $routes = path('t', '06_helpers', 'routes.pl');

ok( -f $routes, "file routes is found");
load $routes;

my $res = get_response_for_request(GET => '/foo');
ok defined($res), "route /foo has been loaded";
