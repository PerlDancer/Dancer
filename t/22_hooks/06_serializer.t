use strict;
use warnings;

use Test::More import => ['!pass'];
use Dancer ':syntax';
use Dancer::Test;

use Time::HiRes qw/gettimeofday/;

plan skip_all => "JSON is needed to run this tests"
    unless Dancer::ModuleLoader->load('JSON');

set serializer => 'JSON';

plan tests => 11;

my $body = '{"foo":"bar"}';

ok(
    hook(
        before_deserializer => sub {
            my $request = Dancer::SharedData->request;
            if ($request->is_put){
                like $request->body, qr/foo/, 'content from PUT is valid';
            }
        }
    ),
    'hook for before_serializer',
);

ok(
    hook(
        after_deserializer => sub {
            my $request = Dancer::SharedData->request;
            if ( $request->is_put ) {
                is $request->params->{foo}, 'bar', 'content from request is ok';
            }
        }
    ),
    'hook for after_deserializer'
);

ok(
    hook(
        before_serializer => sub {
            my $response = shift;
            my ( undef, $start ) = gettimeofday;
            $response->content->{start_time} = $start;
        }
    ),
    'hook for before_serializer'
);

ok(
    hook(
        after_serializer => sub {
            my $response = shift;
            like $response->content, qr/\"start_time\" :/, 'content is ok inside hook';
        }
    ),
    'hook for after_serializer'
);

get '/' => sub { { foo => 1 } };
put '/' => sub { { foo => 1 } };

route_exists [ GET => '/' ], 'route exists';
response_content_like( [ GET => '/' ], qr/start_time/, 'content is ok' );

my $response = dancer_response(
    PUT => '/',
    { body => $body, headers => [ 'Content-Type' => 'application/json' ] }
);

like $response->content, qr/start_time/, 'content is ok';
