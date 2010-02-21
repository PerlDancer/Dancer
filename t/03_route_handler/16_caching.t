#!perl

# testing caching mechanism

use strict;
use warnings;

use Test::More tests => 14, import => ['!pass'];
use lib 't';
use TestUtils;

use Dancer;
use Dancer::Config 'setting';

setting cache => 1;

{
    use Dancer::Route::Cache;
    # checking the size parsing
    my %sizes = (
        '1G'  => 1073741824,
        '10M' => 10485760,
        '10K' => 10240,
        '300' => 300,
    );

    while ( my ( $size, $expected ) = each %sizes ) {
        my $got = Dancer::Route::Cache->parse_size($size);
        cmp_ok( $got, '==', $expected, "Parsing $size correctly ($got)" );
    }

    # checking we can start cache correctly
    my $cache = Dancer::Route::Cache->new(
        size_limit => '10M',
        path_limit => 10

    );

    cmp_ok( $cache->size_limit, '==', $sizes{'10M'}, 'setting size_limit' );
    cmp_ok( $cache->path_limit, '==', 10,            'setting path_limit' );
}

# running three routes
ok( get(  '/:p', sub { params->{'p'} eq 'in' or pass } ), 'adding POST /:p' );
ok( post( '/:p', sub { params->{'p'} eq 'in' or pass } ), 'adding GET  /:p' );
ok( any(  '/:p', sub { 'any' } ),                         'adding any  /:p' );

my %reqs = (
    '/'    => 'GET / request',
    '/var' => 'GET /var request',
);

foreach my $method ( qw/get post/ ) {
    foreach my $path ( '/in', '/out' ) {
        my $req = TestUtils::fake_request( $method => $path );
        Dancer::SharedData->request($req);
        my $res = Dancer::Renderer::get_action_response();

        ok( defined $res, "$method $path request" );
    }
}

my $cache = Dancer::Route->cache;
isa_ok( $cache, 'Dancer::Route::Cache' );

# checking when path doesn't exist
is( $cache->route_from_path('/this/wont/work'), undef, 'non-existing path' );

# checking to see paths are cached
my $route = $cache->route_from_path('/in');
