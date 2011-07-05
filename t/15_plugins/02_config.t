use strict;
use warnings;
use Dancer::ModuleLoader;
use Test::More import => ['!pass'];

plan skip_all => "YAML is needed for this test"
    unless Dancer::ModuleLoader->load('YAML');

plan skip_all => "File::Temp 0.22 required"
    unless Dancer::ModuleLoader->load( 'File::Temp', '0.22' );

plan tests => 9;

use Dancer ':syntax';
use Dancer::Config;
use File::Spec;
use lib File::Spec->catdir( 't', 'lib' );
use TestUtils;

my $dir = File::Temp::tempdir(CLEANUP => 1, TMPDIR => 1);
set appdir => $dir, confdir => $dir;
mkdir File::Spec->catdir( $dir, 'environments' );
set environment => 'test';

my $conffile = Dancer::Config->conffile;
write_file( $conffile => << 'CONF' );
logger: Null
plugins:
  Test:
    foo: bar
  My::Other::Plugin:
    path: /
CONF

my $envfile = Dancer::Config->environment_file;
write_file( $envfile => << 'CONF' );
plugins:
  Test:
    foo: baz
CONF

ok( Dancer::Config->load, 'Config load works with a conffile' );

{

    package Dancer::Plugin::Test;
    use Dancer::Plugin;

    sub conf {
        plugin_setting;
    }
}
{

    package My::Other::Plugin;
    use Dancer::Plugin;

    sub conf {
        plugin_setting;
    }
}
{

    package Yet::Another::Plugin;
    use Dancer::Plugin;

    sub conf {
        plugin_setting;
    }
}

ok my $plugin_conf = Dancer::Plugin::Test::conf(), 'got config for plugin';
is_deeply $plugin_conf, { foo => 'baz' }, 'config is valid';

ok $plugin_conf = My::Other::Plugin::conf(), 'got config for plugin';
is_deeply $plugin_conf, { path => '/' }, 'config is valid';

ok $plugin_conf = Yet::Another::Plugin::conf(), 'got config for plugin';
is_deeply $plugin_conf, { }, 'config is valid';

$plugin_conf->{zlonk} = 'bam';
ok $plugin_conf = Yet::Another::Plugin::conf(), 'got config for plugin';
is_deeply $plugin_conf, { zlonk => 'bam' }, 'config is valid (modified)';

unlink $conffile;
File::Temp::cleanup();
