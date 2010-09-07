use Test::More import => ['!pass'];

plan skip_all => "Plack is needed for this test"
    unless Dancer::ModuleLoader->load('Plack::Request');

plan tests => 4;

use Dancer ':syntax';

is(setting('apphandler'), 'Standalone', 'default apphandler is standalone');
my $app = Dancer::Handler->get_handler;
is(ref($app), 'Dancer::Handler::Standalone', 'got expected handler');

set apphandler => 'PSGI';
is(setting('apphandler'), 'PSGI', 'PSGI is set');
$app = Dancer::Handler->get_handler;
is(ref($app), 'Dancer::Handler::PSGI', 'got expected handler');
