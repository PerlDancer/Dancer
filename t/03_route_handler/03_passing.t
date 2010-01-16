use strict;
use warnings;
use Test::More tests => 19, import => ['!pass'];
use lib 't';
use TestUtils;

BEGIN { 
    use_ok 'Dancer';
    use_ok 'Dancer::Route'; 
}

ok(get('/say/:char' => sub { 
    pass and return false if length(params->{char}) > 1;
    "char: ".params->{char};
}), 'route /say/:char defined');

ok(get('/say/:number' => sub { 
    pass and return false if params->{number} !~ /^\d+$/;
    "number: ".params->{number};
}), 'route /say/:number defined');

ok(get({regexp => '/say/_(.*)'} => sub { 
    "underscore: ".params->{splat}[0];
}), 'route /say/_(.*) defined');

ok(get('/say/:word' => sub { 
    pass and return false if params->{word} =~ /trash/;
    "word: ".params->{word};
}), 'route /say/:word defined');

ok(get('/say/*' => sub { 
    "trash: ".params->{splat}[0];
}), 'route /say/* defined');

my @tests = ( 
    {path => '/say/A', expected => 'char: A'},
    {path => '/say/24', expected => 'number: 24'},
    {path => '/say/B', expected => 'char: B'},
    {path => '/say/Perl', expected => 'word: Perl'},
    {path => '/say/_stuff', expected => 'underscore: stuff'},
    {path => '/say/go_to_trash', expected => 'trash: go_to_trash'},
);

foreach my $test (@tests) {
    my $path = $test->{path};
    my $expected = $test->{expected};
 
    my $request = fake_request(GET => $path);
    Dancer::SharedData->request($request);

    my $response = Dancer::Renderer::get_action_response();
       
    ok( defined($response), "route found for path `$path'");
    is_deeply(
        $response->{content}, $expected, 
        "match data for path `$path' looks good");
}
