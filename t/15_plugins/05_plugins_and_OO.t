use strict;
use warnings;
use Test::More import => ['!pass'];
plan tests => 2;

{
    use Dancer ':syntax';

    # This plugin already inherits from Data::Dumper
    use t::lib::TestPlugin2;
    
    load_app 't::lib::Forum';

    # Make sure the keyword is well registerd
    is(some_other_plugin_keyword(), 42, 'plugin keyword is exported');

    # Make sure the plugin is still a Data::Dumper child
    my $d = t::lib::TestPlugin2->new( [ 1, 2 ], [ qw(foo bar) ] );
    is($d->Dump(), "\$foo = 1;\n\$bar = 2;\n");
}
