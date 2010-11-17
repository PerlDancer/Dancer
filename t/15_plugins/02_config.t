use strict;
use warnings;
use Dancer::ModuleLoader;
use Test::More import => ['!pass'];

plan skip_all => "YAML is needed for this test"
    unless Dancer::ModuleLoader->load('YAML');
plan tests => 5;

use Dancer ':syntax';
use Dancer::Config;
use File::Spec;
use lib File::Spec->catdir( 't', 'lib' );
use TestUtils;

use File::Temp qw/tempdir/;

my $dir = tempdir(CLEANUP => 1);
set(appdir => $dir);
set(confdir => $dir);

my $conffile = Dancer::Config->conffile;

my $conf = '
plugins:
  Test:
    foo: bar
  My::Other::Plugin:
    path: /
';

write_file( $conffile => $conf );
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

ok my $plugin_conf = Dancer::Plugin::Test::conf(), 'got config for plugin';
is_deeply $plugin_conf, { foo => 'bar' }, 'config is valid';

ok $plugin_conf = My::Other::Plugin::conf(), 'got config for plugin';
is_deeply $plugin_conf, { path => '/' }, 'config is valid';

unlink $conffile;
File::Temp::cleanup();
