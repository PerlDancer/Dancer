use Test::More tests => 8, import => ['!pass'];
use strict;
use warnings;

use Dancer::Test;

{
    use Dancer;

    load_app 't::lib::TestApp';
    load_app 't::lib::Forum', prefix => '/forum';

    get '/' => sub { "home" };
}

my $apps = [ Dancer::App->applications ];
is scalar(@$apps), 3, "3 applications exist";

my $main     = Dancer::App->get('main');
my $test_app = Dancer::App->get('t::lib::TestApp');
my $forum    = Dancer::App->get('t::lib::Forum');

ok defined($main), "app 'main' is defined";
ok defined($test_app), "app 't::lib::TestApp' is defined";
ok defined($forum), "app 't::lib::Forum' is defined";

is @{ $main->registry->routes->{'get'} }, 1, 
    "one route is defined in main app";

is @{ $test_app->registry->routes->{'get'} }, 11, 
    "9 routes are defined in main app";

response_content_is [GET => "/forum/index"], "forum index"; 
response_content_is [GET => "/forum"], "root"; 
