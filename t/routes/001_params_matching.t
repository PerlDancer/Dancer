use strict;
use warnings;
use Test::More 'no_plan';

BEGIN { 
    use_ok 'Dancer';
    use_ok 'Dancer::Registry'; 
}

# Register a couple of routes
{
    ok(get('/' => sub { 'first' }), 'first route set');
    ok(get('/hello/:name' => sub { $_[0]->{name}; }), 'second route set');
    ok(get('/hello/:foo/bar' => sub { $_[0]->{foo} }), 'third route set');
}

# then make sure everything looks OK

my $handle = Dancer::Registry->find_route('/');
ok( $handle, 'route found for /');
is(Dancer::Registry->call_route($handle), 'first', 'first route is OK');

$handle = Dancer::Registry->find_route('/hello');
ok( !defined($handle), 'no route found for /hello');

$handle = Dancer::Registry->find_route('/hello/sukria');
ok( $handle, 'route found for /hello/sukria');
is(Dancer::Registry->call_route($handle), 'sukria', 'simple param match found');

$handle = Dancer::Registry->find_route('/hello/sukria/bar');
ok( $handle, 'route found for /hello/sukria/bar');
is(Dancer::Registry->call_route($handle), 'sukria', 'wrapped param match found');
