use strict;
use warnings;
use Test::More 'no_plan', import => ['!pass'];

BEGIN { 
    use_ok 'Dancer';
    use_ok 'Dancer::Route'; 
}

{
    ok(get('/hello/*' => sub { [splat] }), 'first route set');
    ok(get('/hello/*/welcome/*' => sub { [splat ] }), 'second route set');
    ok(get('/download/*.*' => sub { [splat] }), 'third route set');
}


my @tests = ( 
    {path => '/hello/sukria', 
     expected => ['sukria']},

    {path => '/hello/alexis/welcome/sukrieh', 
     expected => ['alexis', 'sukrieh']},

    {path => '/download/wolverine.pdf',
     expected => ['wolverine', 'pdf']},
);

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
