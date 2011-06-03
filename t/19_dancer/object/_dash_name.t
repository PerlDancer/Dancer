use Test::More tests => 1;
use Dancer::Script;

my $script = Dancer::Script->new(appname => 'Hello::World', path => '.', check_version => '1');

isnt( $script->_dash_name, $script->{appname}, '_dash_name parses appname correctly.'); 
