use strict;
use warnings;

use Test::More 'no_plan', import => ['!pass'];

BEGIN {
    use_ok 'Dancer';
    use_ok 'Dancer::Route';
}

{
    ok(get('/' => sub { 'index' }), 'first route set');
    ok(get('/hello/:name' => sub { params->{name} }), 'second route set');
    ok(get('/hello/:foo/bar' => sub { params->{foo} }), 'third route set');
}

my @tests = (
    {path => '/', expected => 'index'},
    {path => '/hello/sukria', expected => 'sukria'},
    {path => '/hello/joe/bar', expected => 'joe' },
);

foreach my $test (@tests) {
    my $cgi = CGI->new;
    $cgi->request_method('GET');
    $cgi->path_info($test->{path});
    
    Dancer::SharedData->cgi($cgi);
    my $response = Dancer::Renderer::get_action_response();

    ok(defined $response, "route handler found for path `".$test->{path}."'");
    is($response->{body}, $test->{expected}, "matching param looks good: ".$response->{body});
}
