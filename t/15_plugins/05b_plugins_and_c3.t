use strict;
use warnings;
use Test::More import => ['!pass'];
plan tests => 3;

SKIP: {
    use Dancer ':syntax';

    # This plugin already inherits from Data::Dumper
    use File::Spec;
    use lib File::Spec->catdir( 't', 'lib' );

    eval { require TestPluginMRO;
           TestPluginMRO->import };

    if (my $error = $@) {

        diag($error);

        if ($error =~ /Can't locate mro\.pm/) {

            # normal error, skip 3
            skip 'mro is not available on this machine', 3;

        } else {

            fail('plugins can be used under the C3 MRO');
            skip 'no point in running the rest', 2;

        }

    } else {

        # this can't be pass because Dancer exports pass() :/
        ok(1, 'plugins can be used under the C3 MRO');

        # and the plugin otherwise behaves.  these tests are cribbed
        # from the existing 05_plugins_and_OO.t
    
        # Make sure the keyword is well registerd
        is(some_other_plugin_keyword(), 42, 'plugin keyword is exported');

        # Make sure the plugin is still a Data::Dumper child
        my $d = TestPluginMRO->new( [ 1, 2 ], [ qw(foo bar) ] );
        is($d->Dump(), "\$foo = 1;\n\$bar = 2;\n");


    }

}
