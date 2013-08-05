use Test::More import => ['!pass'];
use strict;
use warnings;
use Dancer ':tests';
use Dancer::Test;

plan tests => 10;

SKIP: {
    skip 'YAML is needed to run this test', 10
      unless Dancer::ModuleLoader->load('YAML');

    set serializer => 'YAML', show_errors => 1;

    get '/'          => sub { { foo => 'bar' } };
    post '/'         => sub { request->params };
    get '/error'     => sub { send_error( { foo => 42 }, 401 ) };
    get '/error_bis' => sub { send_error( 42, 402 ) };
    get '/yaml'  => sub {
        content_type('text/x-yaml');
        to_yaml( { foo => 'bar' } );
    };

    for my $route ( '/', '/yaml' ) {
        my $res = dancer_response( GET => $route );
        is $res->header('Content-Type'), 'text/x-yaml';
        like $res->content, qr/foo: bar/;
    }

    my $res = dancer_response(
        POST => '/',
        {
            params  => { foo            => 1 },
            headers => [ 'Content-Type' => 'text/x-yaml' ]
        }
    );
    is_deeply(
        from_yaml( $res->content ),
        { foo => 1 },
        "data is correctly deserialized"
    );
    is $res->header('Content-Type'), 'text/x-yaml',
      'goodcontent type set in response';

    $res = dancer_response( GET => '/error' );
    is $res->status, 401;
    is_deeply( from_yaml( $res->content ), { foo => 42 } );

    $res = dancer_response( GET => '/error_bis' );
    is $res->status, 402;
    is_deeply( from_yaml( $res->content ), { error => 42 } );
}
