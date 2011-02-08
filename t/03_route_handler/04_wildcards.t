use strict;
use warnings;
use Test::More import => ['!pass'];

use File::Spec;
use lib File::Spec->catdir( 't', 'lib' );
use TestUtils;

use Dancer ':syntax';
use Dancer::Route; 

my @paths = (
    '/hello/*', 
    '/hello/*/welcome/*', 
    '/download/*.*', 
    '/optional/?*?');

my @tests = ( 
    {path => '/hello/sukria', 
     expected => ['sukria']},

    {path => '/hello/alexis/welcome/sukrieh', 
     expected => ['alexis', 'sukrieh']},

    {path => '/download/wolverine.pdf',
     expected => ['wolverine', 'pdf']},

     { path => '/optional/alexis', expected => ['alexis'] },
     { path => '/optional/', expected => [] },
     { path => '/optional', expected => [] },
);

my $nb_tests = (scalar(@paths)) + (scalar(@tests) * 2);
plan tests => $nb_tests;

ok(get($_ => sub { [splat] }), "route $_ is set") for @paths;

foreach my $test (@tests) {
    my $path = $test->{path};
    my $expected = $test->{expected};
    
    my $request = fake_request(GET => $path);

    Dancer::SharedData->request($request);
    my $response = Dancer::Renderer::get_action_response();
    
    ok( defined($response), "route handler found for path `$path'");
    is_deeply(
        $response->{content}, $expected, 
        "match data for path `$path' looks good");
    Dancer::SharedData->reset_all();
}
