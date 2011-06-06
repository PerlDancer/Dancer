use strict;
use warnings;
use Test::More tests => 2; 
use Dancer::Script;

my $script = Dancer::Script->new(appname => 'Hello', path => '.', check_version => '1');
my $jquery = $script->jquery_minified;

ok ( defined $jquery, 'jquery_minified returns a jquery code.');
ok ( $jquery =~ m/jQuery JavaScript Library/i, 'jQuery string identified.');
