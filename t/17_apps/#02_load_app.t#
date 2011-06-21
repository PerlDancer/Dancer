use Test::More tests => 8, import => ['!pass'];
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

is @{ $test_app->registry->routes->{'get'} }, 13, 
    "13 routes are defined in test app";

response_content_is [GET => "/forum/index"], "forum index"; 
response_content_is [GET => "/forum/"], "root"; 
