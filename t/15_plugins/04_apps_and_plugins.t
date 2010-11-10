use strict;
use warnings;
use Test::More import => ['!pass'];
plan tests => 1;

{
    use Dancer ':syntax';
    use File::Spec;
    use lib File::Spec->catdir( 't', 'lib' );
    use TestPlugin;
    
    load_app 'Forum';
    is(some_plugin_keyword(), 42, 'plugin keyword is exported');
}
