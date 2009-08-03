use Test::More 'no_plan', import => ['!pass'];

use Dancer;
use Dancer::Config 'setting';

is(setting('environment'), undef, 
'default environment is undefined');

set environment => 'development';

my $file = path(setting('appdir'), 'environments', "development.pl");

ok(Dancer::Environment->load('development'), "development environment loaded");

eval { Dancer::Environment->load('foobar') };
like($@, qr/Environment `foobar' not found/, "invalid environment detected");

