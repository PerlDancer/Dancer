use Test::More tests => 4;
use strict;
use warnings;

use Dancer::App;

my $app = Dancer::App->new;

is_deeply $app->settings, {}, 
    "settings is an empty hashref";

is $app->setting('foo'), undef,
    "setting 'foo' is undefined";

ok $app->setting('foo' => 42), 
    "set the 'foo' setting to 42";

is $app->setting('foo'), 42,
    "setting 'foo' is 42";
