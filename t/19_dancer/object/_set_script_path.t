use Test::More tests => 1;
use Dancer::Script;

my $script = Dancer::Script->new(appname => 'Hello::World', path => '.', check_version => '1');

is( $script->{dancer_script}, $script->_dash_name, "_set_script_path sets correctly ->{dancer_script}");
