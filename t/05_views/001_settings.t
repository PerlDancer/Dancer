use Test::More tests => 2, import => ['!pass'];

use Dancer;
use Dancer::Config;

my $views = Dancer::Config::setting('views');
ok(defined($views), "the views directory is defined: $views");

my $layout = Dancer::Config::setting('layout');
ok(!defined($layout), 'layout is not defined');
