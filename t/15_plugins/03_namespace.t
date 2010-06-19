# issue #72
# http://github.com/sukria/Dancer/issues#issue/72

use Test::More tests => 2, import => ['!pass'];

use lib 't';
{
    use Dancer;
    use TestAppExt;
    
    load_plugin 'TestPlugin';

    is(test_plugin_symbol(), "test_plugin_symbol",
        "plugin symbol is exported in current namespace");
    is(TestAppExt::test_app_func(), "test_plugin_symbol",
        "external module has also plugin's symbol");
}
