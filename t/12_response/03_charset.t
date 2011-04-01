use Test::More import => ['!pass'];
use strict;
use warnings;

use Dancer;
use Dancer::ModuleLoader;

use Encode;

plan tests => 16;

set environment => 'production';

my $res = Dancer::Response->new(headers => [ 'Content-Type' => 'text/html' ], content_type => 'text/html');
my $psgi_res = Dancer::Handler->render_response($res);
is(@$psgi_res, 3);
is($psgi_res->[0], 200, 'default status');
is_deeply($psgi_res->[1], [ 'Content-Length', 0, 'Content-Type' => 'text/html' ], 'default headers');
is_deeply($psgi_res->[2], [''], 'default content');

ok $res->content_type('text/plain');
ok $res->content('123');

is_deeply(Dancer::Handler->render_response($res),
    [
        200,
        [ 'Content-Length', 0, 'Content-Type', 'text/plain' ],
        [ '123' ],
    ],
);

setting charset => 'utf-8';

is_deeply(Dancer::Handler->render_response($res),
    [
        200,
        [ 'Content-Length', 0, 'Content-Type', 'text/plain; charset=utf-8' ],
        [ '123' ],
    ],
);

ok $res->content("\x{0429}");   # cyrillic shcha -- way beyond latin1

is_deeply(Dancer::Handler->render_response(Dancer::Serializer->process_response($res)),
    [
        200,
        [ 'Content-Length', 0, 'Content-Type', 'text/plain; charset=utf-8' ],
        [ Encode::encode('utf-8', "\x{0429}") ],
    ],
);

SKIP: {
    skip "JSON is needed for this test" , 3
        unless Dancer::ModuleLoader->load('JSON');

    setting serializer => 'JSON';
    ok $res->content_type('application/json');
    ok $res->content({ key => 'value'});

    is_deeply(Dancer::Handler->render_response(Dancer::Serializer->process_response($res)),
        [
            200,
            [ 'Content-Length', 0, 'Content-Type', 'application/json; charset=utf-8' ],
            [ JSON::to_json({ key => 'value' }) ],
        ],
    );
}

SKIP: {
    skip "XML::Simple is needed for this test" , 3
        unless Dancer::ModuleLoader->load('XML::Simple');

    skip "XML::Parser or XML::SAX are needed to run this test", 3
        unless Dancer::ModuleLoader->load('XML::Parser') or
               Dancer::ModuleLoader->load('XML::SAX');

    setting serializer => 'XML';
    ok $res->content_type('text/xml');
    ok $res->content({ key => "\x{0429}" });

    is_deeply(Dancer::Handler->render_response(Dancer::Serializer->process_response($res)),
        [
            200,
            [ 'Content-Length', 0, 'Content-Type', 'text/xml; charset=utf-8' ],
            [ Encode::encode('utf-8', XML::Simple::XMLout( { key => "\x{0429}"
                    }, RootName => 'data' )) ],
        ],
    );
}
