# testing caching mechanism
use strict;
use warnings;

use Test::More tests => 105, import => ['!pass'];
use File::Spec;
use lib File::Spec->catdir( 't', 'lib' );
use TestUtils;

use Dancer ':syntax';
setting route_cache => 1;

{
    # checking the size parsing
    use Dancer::Route::Cache;

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
        path_limit => 10,
    );

    isa_ok( $cache, 'Dancer::Route::Cache' );
    cmp_ok( $cache->size_limit, '==', $sizes{'10M'}, 'setting size_limit' );
    cmp_ok( $cache->path_limit, '==', 10,            'setting path_limit' );
}

# running three routes
# GET and POST with in pass to 'any'
ok( get(  '/:p', sub { params->{'p'} eq 'in' or pass } ), 'adding POST /:p' );
ok( post( '/:p', sub { params->{'p'} eq 'in' or pass } ), 'adding GET  /:p' );
ok( any(  '/:p', sub { 'any' } ),                         'adding any  /:p' );

my %reqs = (
    '/'    => 'GET / request',
    '/var' => 'GET /var request',
);

foreach my $method ( qw/get post/ ) {
    foreach my $path ( '/in', '/out', '/err' ) {
        my $req = TestUtils::fake_request( $method => $path );
        Dancer::SharedData->request($req);
        my $res = Dancer::Renderer::get_action_response();

        ok( defined $res, "$method $path request" );
    }
}

my $cache = Dancer::Route::Cache->get;
isa_ok( $cache, 'Dancer::Route::Cache' );

# checking when path doesn't exist
is(
    $cache->route_from_path( get => '/wont/work'),
    undef,
    'non-existing path',
);

is(
    $cache->route_from_path( post => '/wont/work'),
    undef,
    'non-existing path',
);

foreach my $method ( qw/get post/ ) {
    foreach my $path ( '/in', '/out', '/err' ) {
        my $route = $cache->route_from_path( $method, $path );
        is( ref $route, 'Dancer::Route', "Got route for $path ($method)" );
    }
}

# since "/out" and "/err" aren't "/in", both GET and POST delegate to "any()"
# that means that "/out" and "/err" on GET should be the same as on POST

foreach my $path ( '/out', '/err' ) {
    my %content; # by method
    foreach my $method ( qw/get post/ ) {
        my $handler = $cache->route_from_path( $method => $path );
        ok( $handler, "Got handler for $method $path" );
        if ($handler) {
            $content{$method} = $handler->{'content'};
        }
    }

    if ( defined $content{'get'} and defined $content{'post'} ) {
        is( $content{'get'}, $content{'post'}, "get/post $path is the same" );
    }
}

# clean up routes
$cache->{'cache'}       = {};
$cache->{'cache_array'} = [];

{
    # testing path_limit
    setting route_cache_path_limit => 10;

    $cache->path_limit(10);

    my @paths = 'a' .. 'z';
    foreach my $path (@paths) {
        ok( get( "/$path", sub {1} ), 'Added path' );
    }

    foreach my $path (@paths) {
        my $req = TestUtils::fake_request( get => "/$path" );
        Dancer::SharedData->request($req);
        my $res = Dancer::Renderer::get_action_response();

        ok( defined $res, "get $path request" );
    }

    # check that only 10 remained
    cmp_ok( $cache->route_cache_paths, '==', 10, 'Path limit to 10' );

    # because we use a FIFO method, we know which ones they are
    my @expected_paths = map { [ 'get', "/$_" ] } 'q' .. 'z';

    is_deeply(
        $cache->{'cache_array'},
        \@expected_paths,
        'Correct paths',
    );
}

# clean up routes
$cache->{'cache'}       = {};
$cache->{'cache_array'} = [];

SKIP: {
    # testing size_limit
    delete $cache->{'path_limit'};

    # doing it manually since parse_size is only in init
    $cache->size_limit( $cache->parse_size('3K') );

    # creating large routes
    my @paths = ();
    foreach my $iter ( 1 .. 10 ) {
        my $all = '';
        while ( length $all < 300 ) {
            $all .= rand 99999;
        }

        push @paths, "/$all";
    }

    foreach my $path (@paths) {
        ok( get( "/$path", sub {1} ), 'Added path' );
    }

    foreach my $path (@paths) {
        my $req = TestUtils::fake_request( get => $path );
        Dancer::SharedData->request($req);
        my $res = Dancer::Renderer::get_action_response();

        ok( defined $res, 'get request' );
    }

    # check that only 10 remained
    cmp_ok( $cache->route_cache_paths, '==', 9, 'Only 9 paths' );

    # because we use a FIFO method, we know which ones they are
    shift @paths;
    my @expected_paths = map { [ 'get', $_ ] } @paths;

    is_deeply(
        $cache->{'cache_array'},
        \@expected_paths,
        'Correct paths',
    );
}
