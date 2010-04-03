use strict;
use warnings;

use Test::More import => ['!pass'], tests => 7;

use_ok 'Dancer';
use_ok 'Dancer::Config';
use lib 't';
use TestUtils;

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
