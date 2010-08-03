use strict;
use warnings;

use Test::More import => ['!pass'];
use Dancer::Test;

plan tests => 26;
use Dancer ':syntax';
use Dancer::Route;

{
    ok( get( '/', { agent => 'foo' } => sub {'agent foo'} ),
        'route / for agent foo defined' );
    
    ok( get('/', { agent => 'bar' }, sub { 'agent bar'} ),
        "route / for agent bar defined");

    ok( get( '/', sub {'all agents'} ), 'route / set without options' );

    ok( get( '/foo', { agent => 'foo' } => sub {'foo only'} ),
        'route /foo for agent foo defined' );

    ok( get('/welcome', {agent => qr{Mozilla}} => sub { "hey Mozilla!" }),
        'route /welcome for agent mozilla defined');

    ok( get('/welcome' => sub { "hello" }),
        'route /welcome without options defined');
}

eval { get '/fail', { false_option => 42 } => sub { } };
like $@, qr/Not a valid option for route matching: `false_option'/, 
    "only supported options are allowed";

my @tests = (
    {method => 'GET', path => '/',    expected => 'agent foo', agent => 'foo'},
    {method => 'GET', path => '/',    expected => 'agent bar',  agent => 'bar'},
    {method => 'GET', path => '/',    expected => 'all agents'},
    
    {method => 'GET', path => '/foo', expected => 'foo only',  agent => 'foo'},
    
    {   method   => 'GET',
        path     => '/welcome',
        expected => 'hey Mozilla!',
        agent    => 'Mozilla/5.0 (X11; U; Linux x86_64; fr; rv:1.9.1.5)'
    },
    {method => 'GET', path => '/welcome', expected => 'hello'},

);

foreach my $test (@tests) {
    $ENV{HTTP_USER_AGENT} = $test->{agent} || undef;
    my $req = [$test->{method} => $test->{path}];
    
    route_exists $req;
    response_exists $req;
    response_content_is $req, $test->{expected};
}

$ENV{HTTP_USER_AGENT} = 'bar';
route_doesnt_exist [GET => '/foo'];

