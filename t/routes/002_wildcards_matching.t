use strict;
use warnings;
use Test::More 'no_plan', import => ['!pass'];

BEGIN { 
    use_ok 'Dancer';
    use_ok 'Dancer::Route'; 
}

{
    ok(get('/hello/*' => sub { $_[0]->{splat} }), 'first route set');
    ok(get('/hello/*/welcome/*' => sub { $_[0]->{splat}; }), 'second route set');
    ok(get('/download/*.*' => sub { $_[0]->{splat} }), 'third route set');
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
    my $handle;
    my $path = $test->{path};
    my $expected = $test->{expected};
    
    $handle = Dancer::Route->find($path);
    ok( defined($handle), "route found for path `$path'");
    is_deeply(
        Dancer::Route->call($handle)->{body}, $expected, 
        "match data for path `$path' looks good");
}
