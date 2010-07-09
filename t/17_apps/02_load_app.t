use Test::More tests => 5, import => ['!pass'];
use strict;
use warnings;

{
    use Dancer;

    load_app 't::lib::TestApp';
    get '/' => sub { "home" };
}

my $apps = [ Dancer::App->applications ];
is scalar(@$apps), 2, "2 applications exist";

my $main = Dancer::App->get('main');
my $test_app = Dancer::App->get('t::lib::TestApp');

ok defined($main), "app 'main' is defined";
ok defined($test_app), "app 't::lib::TestApp' is defined";

is @{ $main->registry->routes->{'get'} }, 1, 
    "one route is defined in main app";

is @{ $test_app->registry->routes->{'get'} }, 8, 
    "8 routes are defined in main app";
