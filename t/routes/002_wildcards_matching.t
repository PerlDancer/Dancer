use strict;
use warnings;
use Test::More 'no_plan';

BEGIN { 
    use_ok 'Dancer';
    use_ok 'Dancer::Registry'; 
}

# Register a couple of routes
{
    ok(get('/hello/*' => sub { $_[0]->{splat} }), 'first route set');
    ok(get('/hello/*/welcome/*' => sub { $_[0]->{splat}; }), 'second route set');
    ok(get('/download/*.*' => sub { $_[0]->{splat} }), 'third route set');
}

# then make sure everything looks OK

my $handle = Dancer::Registry->find_route('/hello');
ok( !defined($handle), 'no route found for /hello');

$handle = Dancer::Registry->find_route('/hello/sukria');
ok( $handle, 'route found for /hello/sukria');
is(Dancer::Registry->call_route($handle)->[0], 'sukria', 'first elem of wildcards array found');

my $expected = [ 'alexis', 'sukrieh' ];
$handle = Dancer::Registry->find_route('/hello/alexis/welcome/sukrieh');
ok( $handle, 'route found for /hello/alexis/welcome/sukrieh');
is_deeply(Dancer::Registry->call_route($handle), $expected, 'two widlcards matched');

# TODO : this looks like we can refactor the test suite ...
my $route = '/download/wolverine.pdf';
$expected = ['wolverine', 'pdf'];
$handle = Dancer::Registry->find_route($route);
ok(defined($handle), "route found for $route");
is_deeply(Dancer::Registry->call_route($handle), $expected, "match for $route looks good");
