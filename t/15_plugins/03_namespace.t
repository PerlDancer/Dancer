# issue #72
# http://github.com/sukria/Dancer/issues#issue/72

use Test::More tests => 3, import => ['!pass'];

{
    use Dancer;
    
    use lib 't';
    use TestPlugin;
    use TestAppExt;
    
    eval { load_plugin 'TestPlugin' };

    like $@, qr{load_plugin is DEPRECATED, you must use 'use' instead},
        "load_plugin is deprecated";

    is(test_plugin_symbol(), "test_plugin_symbol",
        "plugin symbol is exported in current namespace");

    is(TestAppExt::test_app_func(), "test_plugin_symbol",
        "external module has also plugin's symbol");

}
