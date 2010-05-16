use strict;
use warnings;
use Test::More tests => 17, import => ['!pass'];

use Dancer ':syntax';
use Dancer::Route; 
use Dancer::Test;

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
       
    response_exists( [GET => $path], 
        "route found for path `$path'");
    response_content_is_deeply([GET => $path], $expected, 
        "match data for path `$path' looks good");
}
