use Test::More import => ['!pass'];
use strict;
use warnings;

use Dancer;
use Dancer::ModuleLoader;
use Dancer::Config 'setting';

use Encode;

plan tests => 9;

my $res = Dancer::Response->new(headers => [ 'Content-Type' => 'text/html' ], content_type => 'text/html');
my $psgi_res = Dancer::Handler->render_response($res);
is(@$psgi_res, 3);
is($psgi_res->[0], 200, 'default status');
is_deeply($psgi_res->[1], [ 'Content-Type' => 'text/html' ], 'default headers');
is_deeply($psgi_res->[2], [''], 'default content');

$res->{content_type} = 'text/plain';
$res->update_headers('Content-Type' => $res->{content_type});
$res->{content} = '123';

is_deeply(Dancer::Handler->render_response($res),
    [
        200,
        [ 'Content-Type', 'text/plain' ],
        [ '123' ],
    ],
);

setting charset => 'utf-8';

is_deeply(Dancer::Handler->render_response($res),
    [
        200,
        [ 'Content-Type', 'text/plain' ],
        [ '123' ],
    ],
);

$res->{content} = "\x{0429}";   # cyrillic shcha -- way beyond latin1

is_deeply(Dancer::Handler->render_response(Dancer::Serializer->process_response($res)),
    [
        200,
        [ 'Content-Type', 'text/plain; charset=utf-8' ],
        [ Encode::encode('utf-8', "\x{0429}") ],
    ],
);

SKIP: {
    skip "JSON is needed for this test" , 1
        unless Dancer::ModuleLoader->load('JSON');

    setting serializer => 'JSON';
    $res->{content_type} = 'application/json';
    $res->{content} = { key => 'value' };
    $res->update_headers('Content-Type' => $res->{content_type});

    is_deeply(Dancer::Handler->render_response(Dancer::Serializer->process_response($res)),
        [
            200,
            [ 'Content-Type', 'application/json' ],
            [ JSON::to_json({ key => 'value' }) ],
        ],
    );
}

SKIP: {
    skip "XML::Simple is needed for this test" , 1
        unless Dancer::ModuleLoader->load('XML::Simple');

    setting serializer => 'XML';
    $res->{content_type} = 'text/xml';
    $res->{content} = { key => "\x{0429}" };
    $res->update_headers('Content-Type' => $res->{content_type}."; charset=utf-8");

    is_deeply(Dancer::Handler->render_response(Dancer::Serializer->process_response($res)),
        [
            200,
            [ 'Content-Type', 'text/xml; charset=utf-8' ],
            [ Encode::encode('utf-8', XML::Simple::XMLout( { data => { key => "\x{0429}" } } )) ],
        ],
    );
}
