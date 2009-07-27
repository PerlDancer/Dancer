use strict;
use warnings;
use Test::More import => ['!pass'];

use Dancer;
use Dancer::Route; 

my @paths = ('/hello/*', '/hello/*/welcome/*', '/download/*.*');

my @tests = ( 
    {path => '/hello/sukria', 
     expected => ['sukria']},

    {path => '/hello/alexis/welcome/sukrieh', 
     expected => ['alexis', 'sukrieh']},

    {path => '/download/wolverine.pdf',
     expected => ['wolverine', 'pdf']},
);

my $nb_tests = (scalar(@paths)) + (scalar(@tests) * 2);
plan tests => $nb_tests;

ok(get($_ => sub { [splat] }), "route $_ is set") for @paths;

foreach my $test (@tests) {
    my $path = $test->{path};
    my $expected = $test->{expected};
    
    my $cgi = CGI->new;
    $cgi->request_method('GET');
    $cgi->path_info($path);

    Dancer::SharedData->cgi($cgi);
    my $response = Dancer::Renderer::get_action_response();
    
    ok( defined($response), "route handler found for path `$path'");
    is_deeply(
        $response->{body}, $expected, 
        "match data for path `$path' looks good");
}
