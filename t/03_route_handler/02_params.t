use Dancer ':syntax', ':tests';
use Dancer::Test;
use Test::More;

plan tests => 28;

# multiple token
{
    get '/:resource/:id.:format' => sub {
        [ params->{'resource'},
          params->{'id'},
          params->{'format'} ];
    };

    my $response = dancer_response(GET => '/user/42.json');
    ok( defined($response), "response found for '/user/42.json'" );

    is_deeply( $response->content, ['user', '42', 'json'],
    "params are parsed as expected" );
}

{
    ok( get( '/'               => sub { 'index' } ),        'first route set' );
    ok( get( '/hello/:name'    => sub { param 'name' } ), 'second route set' );
    ok( get( '/hello/:foo/bar' => sub { param 'foo' } ), 'third route set' );
    ok( post( '/new/:stuff'    => sub { param 'stuff'} ), 'post 1 route set' );
    ok( post( '/allo'          => sub { request->body } ),   'post 2 route set' );

    get '/opt/:name?/?:lastname?' => sub {
        [ params->{name}, params->{lastname} ];
    };

    my @tests = (
        { method => 'GET',  path => '/',              expected => 'index' },
        { method => 'GET',  path => '/hello/sukria',  expected => 'sukria' },
        { method => 'GET',  path => '/hello/joe/bar', expected => 'joe' },
        { method => 'POST', path => '/new/wine',      expected => 'wine' },

        {
            method   => 'GET',
            path     => '/opt/',
            expected => [ undef, undef ]
        },

        {
            method   => 'GET',
            path     => '/opt/placeholder',
            expected => [ 'placeholder', undef ]
        },

        {
            method   => 'GET',
            path     => '/opt/alexis/sukrieh',
            expected => [ "alexis", "sukrieh" ]
        },
    );

    foreach my $test (@tests) {
        my $req = [ $test->{method}, $test->{path} ];

        route_exists $req;

        if ( ref( $test->{expected} ) ) {
            response_content_is_deeply $req => $test->{expected};
        }
        else {
            response_content_is $req => $test->{expected};
        }

        # splat should not be set
        ok( !exists( params->{'splat'} ),
            "splat not defined for " . $test->{path} );
    }

}
