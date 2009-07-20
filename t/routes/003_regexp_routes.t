use strict;
use warnings;
use Test::More 'no_plan';

BEGIN { 
    use_ok 'Dancer';
    use_ok 'Dancer::Route'; 
}

ok(get({regexp => '/hello/([\w]+)'} => sub { $_[0]->{splat} }), 'first route set');
ok(get({regexp => '/show/([\d]+)'} => sub { $_[0]->{splat} }), 'second route set');
ok(get({regexp => '/post/([\w\d\-\.]+)/#comment([\d]+)'} => sub { $_[0]->{splat} }), 'third route set');

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
    
    $handle = Dancer::Route->find($path);
    ok( defined($handle), "route found for path `$path'");
    is_deeply(
        Dancer::Route->call($handle)->{body}, $expected, 
        "match data for path `$path' looks good");
}
