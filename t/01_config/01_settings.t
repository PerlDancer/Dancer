use strict;
use warnings;

use Test::More tests => 11, import => ['!pass'];

use Dancer ':syntax';

# testing default values
is(setting('port'), '3000', "default value for 'port' is OK"); 
is(setting('content_type'), 'text/html', "default value for 'content_type' is OK"); 

# testing new settings
ok(setting(foo => '42'), 'setting a new value');
is(setting('foo'), 42, 'new value has been set');

# test the alias 'set'
ok(set(bar => 43), "setting bar with set");

# testing private interface
is( Dancer::Config::_set_setting( bar => 42 ),
    42, 'setting bar with private interface' );
is( Dancer::Config::_get_setting('bar'),
    42, 'getting bar with private interface' );

SKIP: {
    skip "YAML and JSON are needed to run this test", 4
      unless ( Dancer::ModuleLoader->load('YAML')
        && Dancer::ModuleLoader->load('JSON') );

    ok my $serializer = Dancer::Config::_trigger_hooks( 'serializer', 'YAML' );
    isa_ok( $serializer, 'Dancer::Serializer::YAML' );
    ok $serializer = Dancer::Config::_trigger_hooks( 'serializer', 'JSON' );
    isa_ok( $serializer, 'Dancer::Serializer::JSON' );
}
