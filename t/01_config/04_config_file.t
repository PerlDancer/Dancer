use strict;
use warnings;
use Test::More import => ['!pass'];

plan skip_all => "YAML needed to run this tests"
    unless Dancer::ModuleLoader->load('YAML');
plan skip_all => "File::Temp 0.22 required"
    unless Dancer::ModuleLoader->load( 'File::Temp', '0.22' );
plan tests => 17;

use Dancer ':syntax';
use File::Spec;
use lib File::Spec->catdir( 't', 'lib' );
use TestUtils;

my $dir = File::Temp::tempdir(CLEANUP => 1, TMPDIR => 1);
set appdir => $dir;
my $envdir = File::Spec->catdir($dir, 'environments');
mkdir $envdir;

my $conffile = Dancer::Config->conffile;
ok(defined($conffile), 'default conffile is defined');

ok(Dancer::Config->load, 'Config load works without conffile');

# create the conffile
my $conf = '
port: 4500
startup_info: 0
charset: "UTF8"
logger: file
';
write_file($conffile => $conf);
ok(Dancer::Config->load, 'Config load works with a conffile');
is(setting('environment'), 'development', 
    'setting environment looks good');
is(setting('port'), '4500',
    'setting port looks good');
is(setting('startup_info'), 0,
    'setting startup_info looks good');
is(setting('logger'), 'file',
    'setting logger looks good');

# issue GH#153
is(setting('charset'), 'utf8',
    "charset setting is normalized");

ok(defined(Dancer::Logger->logger), 'logger is defined');

my $test_env = '
log: debug
startup_info: 1
foo_test: 54
';
write_file(Dancer::Config->environment_file, $test_env);
ok(Dancer::Config->load, 'load test environment');
is(setting('log'), 'debug', 'log setting looks good'); 
is(setting('startup_info'), '1', 'startup_info setting looks good'); 
is(setting('foo_test'), '54', 'random setting set'); 
unlink Dancer::Config->environment_file;

my $prod_env = '
log: "warning"
startup_info: 0
foo_prod: 42
';

setting('environment' => 'prod');
write_file(Dancer::Config->environment_file, $prod_env);

ok(Dancer::Config->load, 'load prod environment');
is(setting('log'), 'warning', 'log setting looks good'); 
is(setting('foo_prod'), '42', 'random setting set'); 
is(setting('startup_info'), '0', 'startup_info setting looks good'); 

Dancer::Logger::logger->{fh}->close;
unlink Dancer::Config->environment_file;
unlink $conffile;
File::Temp::cleanup();
