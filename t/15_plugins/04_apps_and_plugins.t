use strict;
use warnings;
use Test::More import => ['!pass'];
plan tests => 1;

{
    use Dancer ':syntax';
    use t::lib::TestPlugin;
    
    load_app 't::lib::Forum';
    is(some_plugin_keyword(), 42, 'plugin keyword is exported');
}
