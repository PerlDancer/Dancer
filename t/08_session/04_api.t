use Test::More import => ['!pass'];
use Dancer ':syntax';
use Dancer::Session::YAML;

plan tests => '4';

use File::Spec;
use lib File::Spec->catdir( 't', 'lib' );
use EasyMocker;

my $fake_session = bless { foo => 42 }, 'Dancer::Session::YAML';

mock 'Dancer::Session'
    => method 'get_current_session' => should sub { $fake_session };
mock 'Dancer::Session::YAML'
    => method 'init' => should sub { 1 };
mock 'Dancer::Session::YAML'
    => method 'create' => should sub { $fake_session };
mock 'Dancer::Session::YAML'
    => method 'retrieve' => should sub { $fake_session };
mock 'Dancer::Session::YAML'
    => method 'flush' => should sub { $fake_session };
mock 'Dancer::Session::YAML'
    => method 'destroy' => should sub { $fake_session };

ok(set(session => 'YAML'), "set session engine to 'YAML'");

is session('foo'), 42, 'session reader works';
ok session('foo' => 54), 'session writer works';

my $expected = bless { foo => 54 }, 'Dancer::Session::YAML';
is_deeply session(), $expected, 
    "session object is returned when no args is given";
