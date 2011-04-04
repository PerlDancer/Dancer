use Test::More import => ['!pass'];
use strict;
use warnings;
use Dancer ':tests';
use Dancer::Test;

plan tests => 10;

SKIP: {
    skip 'YAML is needed to run this test', 10
      unless Dancer::ModuleLoader->load('JSON');

    setting( 'serializer' => 'JSON' );
    setting( 'show_errors' => 1);

    get '/' => sub { { foo => 'bar' } };
    post '/'     => sub { request->params };
    get '/json'  => sub { to_json( { foo => 'bar' } ) };
    get '/error' => sub { send_error( { foo => 42 }, 401 ) };
    get '/error_bis' => sub { send_error( 42, 402 ) };

    for ( '/', '/json' ) {
        my $res = dancer_response( GET => '/' );
        is $res->header('Content-Type'), 'application/json';
        like $res->content, qr/"foo" : "bar"/;
    }

    my $res = dancer_response(
        POST => '/',
        {
            params  => { foo            => 1 },
            headers => [ 'Content-Type' => 'application/json' ]
        }
    );
    is_deeply(
        from_json( $res->content ),
        { foo => 1 },
        "data is correctly deserialized"
    );
    is $res->header('Content-Type'), 'application/json',
      'goodcontent type set in response';

    $res = dancer_response( GET => '/error' );
    is $res->status, 401;
    is_deeply( from_json( $res->content ), { foo => 42 } );

    $res = dancer_response( GET => '/error_bis' );
    is $res->status, 402;
    is_deeply( from_json( $res->content ), { error => 42 } );
}
