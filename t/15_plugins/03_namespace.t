# issue #72
# https://github.com/PerlDancer/Dancer/issues#issue/72

use Test::More tests => 2, import => ['!pass'];

{
    use Dancer;
    
    use lib 't';
    use TestPlugin;
    use TestAppExt;
    
    is(test_plugin_symbol(), "test_plugin_symbol",
        "plugin symbol is exported in current namespace");

    is(TestAppExt::test_app_func(), "test_plugin_symbol",
        "external module has also plugin's symbol");

}
