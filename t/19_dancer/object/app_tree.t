use strict;
use warnings;
use Test::More tests => 1;
use Dancer::Script;

my $script = Dancer::Script->new(appname => 'Hello', path => '.', check_version => '1');
my $list = $script->app_tree;
ok (defined $list, 'app_tree successfully returns a list.');


