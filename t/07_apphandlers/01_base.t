use Test::More 'no_plan', import => ['!pass'];

use Dancer;
use Dancer::Config 'setting';

is(setting('apphandler'), 'standalone', 'default apphandler is standalone');
my $app = Dancer::Handler->get_handler;
is(ref($app), 'Dancer::Handler::Standalone', 'got expected handler');

set apphandler => 'PSGI';
is(setting('apphandler'), 'PSGI', 'PSGI is set');
$app = Dancer::Handler->get_handler;
is(ref($app), 'Dancer::Handler::PSGI', 'got expected handler');
