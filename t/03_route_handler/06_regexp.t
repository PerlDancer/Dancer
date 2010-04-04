use strict;
use warnings;
use Test::More 'no_plan', import => ['!pass'];

use t::lib::TestUtils;

use Dancer ':syntax';
use Dancer::Route; 

ok(get(r('/hello/([\w]+)') => sub { [splat] }), 'first route set');
ok(get(r('/show/([\d]+)') => sub { [splat] }), 'second route set');
ok(get(r('/post/([\w\d\-\.]+)/#comment([\d]+)') => sub { [splat] }), 'third route set');

my @tests = ( 
    {path => '/hello/sukria', 
     expected => ['sukria']},

    {path => '/show/245', 
     expected => ['245']},

    {path => '/post/this-how-to-write-smart-webapp/#comment412',
     expected => ['this-how-to-write-smart-webapp', '412']},
);

foreach my $test (@tests) {
    my $handle;
    my $path = $test->{path};
    my $expected = $test->{expected};
 
    my $request = fake_request(GET => $path);

    Dancer::SharedData->request($request);
    my $response = Dancer::Renderer::get_action_response();
       
    ok( defined($response), "route handler found for path `$path'");
    is_deeply(
        $response->{content}, $expected, 
        "match data for path `$path' looks good");
}
