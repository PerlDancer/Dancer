use Test::More import => ['!pass'];
use strict;
use warnings;
use Dancer ':tests';
use Dancer::Test;

BEGIN {
    plan skip_all => "need JSON"
      unless Dancer::ModuleLoader->load('JSON');

    plan tests => 11;
}

set 'serializer' => 'JSON', 'show_errors' => 1;

get  '/'          => sub { { foo => 'bar' } };
post '/'          => sub { params };
put  '/'          => sub { param("id") };
get  '/error'     => sub { send_error( { foo => 42 }, 401 ) };
get  '/error_bis' => sub { send_error( 42, 402 ) };
get  '/json'      => sub {
    content_type('application/json');
    to_json( { foo => 'bar' } )
};

response_content_is [ PUT => '/',
                      {
                       body    => '{"id": "foo"}' ,
                       headers => [ 'Content-Type' => 'application/json' ],
                      }
                    ] => 'foo';


for my $route ( '/', '/json' ) {
    my $res = dancer_response( GET => $route );
    is $res->header('Content-Type'), 'application/json';
    like $res->content, qr/"foo" : "bar"/;
}

my $res = dancer_response
  (
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

