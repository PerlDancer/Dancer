use strict;
use warnings;
use Test::More;

use Dancer::App;

plan tests => 3;

ok my $app = Dancer::App->new();

ok $app->app_exists('main');
ok !$app->app_exists('foo');
