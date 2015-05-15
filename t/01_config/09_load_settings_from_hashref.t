use strict;
use warnings;
use Test::More import => ['!pass'];

plan skip_all => "YAML needed to run this tests"
    unless Dancer::ModuleLoader->load('YAML');
plan skip_all => "File::Temp 0.22 required"
    unless Dancer::ModuleLoader->load( 'File::Temp', '0.22' );
plan tests => 9;

use Dancer ':syntax';
use File::Spec;
use lib File::Spec->catdir( 't', 'lib' );
use TestUtils;

my $dir = File::Temp::tempdir(CLEANUP => 1, TMPDIR => 1);
set appdir => $dir;
my $envdir = File::Spec->catdir($dir, 'environments');
mkdir $envdir;

ok(Dancer::Config->load({ different => 'config' }),
   'load settings entirely from hashref');

is(setting('different'),
   'config',
   'settings from hashref can be read');

my $conffile = Dancer::Config->conffile;

# create the conffile
my $conf = '
port: 4500
charset: "UTF8"
startup_info: 0
logger: file
log: info
structure:
  key1: value1
  key2: value2
';
write_file($conffile => $conf);

# create the env file
my $test_env = '
startup_info: 1
foo_test: 54
';
write_file(Dancer::Config->environment_file, $test_env);

ok(Dancer::Config->load({ startup_info => 2,
                          structure => { key1 => 'modified_value1',
                                         key3 => 'added_value3' } }),
   'load settings from hashref');

# regular cases:
is(setting('port'),
   4500,
   'settings from the config file are used');
is(setting('foo_test'),
   54,
   'settings from the env file are used');
is(setting('log'),
   'info',
   'settings from the env file still override the config file');

# hashref cases:
is(setting('startup_info'),
   2,
   'settings from the hashref override both');
is_deeply(setting('structure'),
          { key1 => 'modified_value1',
            key2 => 'value2',
            key3 => 'added_value3' },
          'settings from the hashref are deep-merged like the rest');

is(setting('different'),
   'config',
   'settings from an old hashref are still set');

Dancer::Logger::logger->{fh}->close;
unlink Dancer::Config->environment_file;
unlink $conffile;
File::Temp::cleanup();
