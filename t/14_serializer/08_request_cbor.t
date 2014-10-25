use Test::More import => ['!pass'];
use strict;
use warnings;
use Dancer ':tests';
use Dancer::Test;

plan tests => 10;

SKIP: {
    skip 'CBOR::XS is needed to run this test', 10
      unless Dancer::ModuleLoader->load('CBOR::XS');

    set serializer => 'CBOR', show_errors => 1;

    get '/'          => sub { { foo => 'bar' } };
    post '/'         => sub { request->params };
    get '/error'     => sub { send_error( { foo => 42 }, 401 ) };
    get '/error_bis' => sub { send_error( 42, 402 ) };
    get '/cbor'  => sub {
        content_type('application/cbor');
        to_cbor( { foo => 'bar' } );
    };

    for my $route ( '/', '/cbor' ) {
        my $res = dancer_response( GET => $route );
        is $res->header('Content-Type'), 'application/cbor';
        
        is $res->content, chr(0xa1).chr(0x40 + 3).'foo'.chr(0x40 + 3).'bar';
    }

    my $res = dancer_response(
        POST => '/',
        {
            params  => { foo            => 1 },
            headers => [ 'Content-Type' => 'application/cbor' ]
        }
    );
    is_deeply(
        from_cbor( $res->content ),
        { foo => 1 },
        "data is correctly deserialized"
    );
    is $res->header('Content-Type'), 'application/cbor',
      'goodcontent type set in response';

    $res = dancer_response( GET => '/error' );
    is $res->status, 401;
    is_deeply( from_cbor( $res->content ), { foo => 42 } );

    $res = dancer_response( GET => '/error_bis' );
    is $res->status, 402;
    is_deeply( from_cbor( $res->content ), { error => 42 } );
}
