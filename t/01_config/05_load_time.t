use strict;
use warnings;

use Test::More import => ['!pass'];
use lib 't';
use TestUtils;


plan skip_all => "YAML is needed to run this test" 
    unless Dancer::ModuleLoader->load('YAML');
plan tests => 2;

{
    package Foo;

    use Dancer;

    if (config->{loaded}) {
        get '/' => sub { "loaded" };
    }
    else {
        get '/' => sub { "not loaded" };
    }
}

my $request = TestUtils::fake_request(get => '/');
Dancer::SharedData->request($request);
my $response = Dancer::Renderer::get_action_response();
ok(defined($response), "route handler found for method get /");
is $response->{content}, 'loaded', "config was loaded before route definition";


