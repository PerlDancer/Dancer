use Dancer ':tests';
use Test::More;

use Dancer::Test;

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

    my $response = dancer_response(GET => $path);
    
    ok( defined($response), "route handler found for path `$path'");
    is_deeply(
        $response->content, $expected, 
        "match data for path `$path' looks good");
}
