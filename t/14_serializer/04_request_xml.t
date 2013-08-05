use Test::More import => ['!pass'];
use strict;
use warnings;
use Dancer ':tests';
use Dancer::Test;

plan tests => 10;

SKIP: {
    skip 'XML::Simple is needed to run this test', 10
      unless Dancer::ModuleLoader->load('XML::Simple');

    skip 'XML::Parser or XML::SAX are needed to run this test', 10
        unless Dancer::ModuleLoader->load('XML::Parser') or
               Dancer::ModuleLoader->load('XML::SAX');

    set serializer => 'XML', show_errors => 1;

    get '/'          => sub { { foo => 'bar' } };
    post '/'         => sub { request->params };
    get '/error'     => sub { send_error( { foo => 42 }, 401 ) };
    get '/error_bis' => sub { send_error( 42, 402 ) };
    get '/xml'       => sub {
        content_type('text/xml');
        to_xml( { foo => 'bar' } )
    };

    for my $route ( '/', '/xml' ) {
        my $res = dancer_response( GET => $route );
        is $res->header('Content-Type'), 'text/xml';
        like $res->content, qr/<data foo="bar" \/>/;
    }

    my $res = dancer_response(
        POST => '/',
        {
            params  => { foo            => 1 },
            headers => [ 'Content-Type' => 'text/xml' ]
        }
    );
    is_deeply(
        from_xml( $res->content ),
        { foo => 1 },
        "data is correctly deserialized"
    );
    is $res->header('Content-Type'), 'text/xml',
      'goodcontent type set in response';

    $res = dancer_response( GET => '/error' );
    is $res->status, 401;
    is_deeply( from_xml($res->content ), { foo => 42 } );

    $res = dancer_response( GET => '/error_bis' );
    is $res->status, 402;
    is_deeply( from_xml( $res->content ), { error => 42 } );
}
