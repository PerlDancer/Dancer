use strict;
use warnings;
use Test::More import => ['!pass'];
use Dancer::ModuleLoader;

Dancer::ModuleLoader->load('YAML')
    or plan skip_all => 'YAML is needed to run this test';

plan tests => 7;

use File::Spec;
use Dancer ':syntax';
use lib File::Spec->catdir('t', 'lib');
use TestUtils;

my $app_dir = File::Temp::tempdir(CLEANUP => 1, TMPDIR => 1);
my $env_dir = File::Temp::tempdir(CLEANUP => 1, TMPDIR => 1);

set appdir => $app_dir;
set envdir => $env_dir;

my $conffile = Dancer::Config->conffile;
my $conf = '
port: 4500
startup_info: 0
charset: "UTF8"
logger: file
log: "debug"
';
write_file($conffile => $conf);

ok(Dancer::Config->load, 'Config load works without conffile');

is(setting('log'), 'debug', 'log setting looks good');

my $prod_env = '
log: "warning"
startup_info: 0
foo_prod: 42
';

setting('environment' => 'prod');
write_file(Dancer::Config->environment_file, $prod_env);

my $path = File::Spec->catfile($env_dir, 'prod.yml');
ok -f $path;

ok(Dancer::Config->load, 'load prod environment');
is(setting('log'), 'warning', 'log setting looks good');

# see what happens when envfile is required but not present
setting('require_environment' => 1);
setting('environment' => 'missing');
# expect it to fail with a confess()
eval { Dancer::Config->load };
ok($@, 'dies if environment required but missing');
like($@, qr/missing\.yml/, '... error message includes environment file name');

File::Temp::cleanup();
