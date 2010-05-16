use Test::More import => ['!pass'];

plan skip_all => "Plack is needed for this test"
    unless Dancer::ModuleLoader->load('Plack');

plan tests => 4;

use Dancer ':syntax';
use Dancer::Config 'setting';

is(setting('apphandler'), 'standalone', 'default apphandler is standalone');
my $app = Dancer::Handler->get_handler;
is(ref($app), 'Dancer::Handler::Standalone', 'got expected handler');

set apphandler => 'PSGI';
is(setting('apphandler'), 'PSGI', 'PSGI is set');
$app = Dancer::Handler->get_handler;
is(ref($app), 'Dancer::Handler::PSGI', 'got expected handler');
