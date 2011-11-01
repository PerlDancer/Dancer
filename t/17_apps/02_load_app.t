use Test::More tests => 12, import => ['!pass'];
use strict;
use warnings;

use Dancer::Test;
use File::Spec;
use lib File::Spec->catdir( 't', 'lib' );

{
    use Dancer;

    load_app 'TestApp';
    load_app 'Forum', prefix => '/forum';

    get '/' => sub { "home" };
}

my $apps = [ Dancer::App->applications ];
is scalar(@$apps), 3, "3 applications exist";

my $main     = Dancer::App->get('main');
my $test_app = Dancer::App->get('TestApp');
my $forum    = Dancer::App->get('Forum');

ok defined($main), "app 'main' is defined";
ok defined($test_app), "app 'TestApp' is defined";
ok defined($forum), "app 'Forum' is defined";

is @{ $main->registry->routes->{'get'} }, 1, 
    "one route is defined in main app";

is @{ $test_app->registry->routes->{'get'} }, 15, 
    "15 routes are defined in test app";

is @{ $forum->registry->routes->{'get'} }, 5, 
    "5 routes are defined in forum app";

response_content_is [GET => "/forum/index"], "forum index"; 
response_content_is [GET => "/forum/admin/index"], "admin index"; 
response_content_is [GET => "/forum/users/list"], "users list"; 
response_content_is [GET => "/forum/users/mods/list"], "mods list"; 
response_content_is [GET => "/forum/"], "root"; 
