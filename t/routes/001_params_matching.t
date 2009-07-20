use strict;
use warnings;
use Test::More 'no_plan';

BEGIN { 
    use_ok 'Dancer';
    use_ok 'Dancer::Route'; 
}

# Register a couple of routes
{
    ok(get('/' => sub { 'first' }), 'first route set');
    ok(get('/hello/:name' => sub { $_[0]->{name}; }), 'second route set');
    ok(get('/hello/:foo/bar' => sub { $_[0]->{foo} }), 'third route set');
}

# then make sure everything looks OK

my $handle = Dancer::Route->find('/');
ok( $handle, 'route found for /');
is(Dancer::Route->call($handle), 'first', 'first route is OK');

$handle = Dancer::Route->find('/hello');
ok( !defined($handle), 'no route found for /hello');

$handle = Dancer::Route->find('/hello/sukria');
ok( $handle, 'route found for /hello/sukria');
is(Dancer::Route->call($handle), 'sukria', 'simple param match found');

$handle = Dancer::Route->find('/hello/sukria/bar');
ok( $handle, 'route found for /hello/sukria/bar');
is(Dancer::Route->call($handle), 'sukria', 'wrapped param match found');
