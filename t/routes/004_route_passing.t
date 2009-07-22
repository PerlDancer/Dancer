use strict;
use warnings;
use Test::More tests => 19, import => ['!pass'];

BEGIN { 
    use_ok 'Dancer';
    use_ok 'Dancer::Route'; 
}

ok(get('/say/:char' => sub { 
    my $params = shift;
    pass and return false if length($params->{char}) > 1;
    "char: ".$params->{char};
}), 'route /say/:char defined');

ok(get('/say/:number' => sub { 
    my $params = shift;
    pass and return false if $params->{number} !~ /^\d+$/;
    "number: ".$params->{number};
}), 'route /say/:number defined');

ok(get({regexp => '/say/_(.*)'} => sub { 
    my $params = shift;
    "underscore: ".$params->{splat}[0];
}), 'route /say/_(.*) defined');

ok(get('/say/:word' => sub { 
    my $params = shift;
    pass and return false if $params->{word} =~ /trash/;
    "word: ".$params->{word};
}), 'route /say/:word defined');

ok(get('/say/*' => sub { 
    my $params = shift;
    "trash: ".$params->{splat}[0];
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
    my $handle;
    my $path = $test->{path};
    my $expected = $test->{expected};
    
    $handle = Dancer::Route->find($path);
    ok( defined($handle), "route found for path `$path'");
    is_deeply(
        Dancer::Route->call($handle)->{body}, $expected, 
        "match data for path `$path' looks good");
}
