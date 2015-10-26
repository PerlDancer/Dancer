use Test::More import => ['!pass'];
use strict;
use warnings;

use Dancer ':tests';
use Dancer::Request;
use Dancer::Serializer;
use Dancer::Serializer::Abstract;

plan tests => 18;

SKIP: {
    skip 'JSON is needed to run this test', 3
      unless Dancer::ModuleLoader->load('JSON');

    ok my $s = Dancer::Serializer->init();

    my $ct = $s->support_content_type();
    ok !defined $ct;

    $ct = $s->content_type();
    is $ct, 'application/json';
}

{

    eval { Dancer::Serializer::Abstract->serialize() };
    like $@, qr{must be implemented}, "serialize is a virtual method";

    eval { Dancer::Serializer::Abstract->deserialize() };
    like $@, qr{must be implemented}, "deserialize is a virtual method";

    is( Dancer::Serializer::Abstract->loaded, 0, "loaded is 0" );

    is( Dancer::Serializer::Abstract->content_type,
        "text/plain", "content_type is text/plain" );

    ok( Dancer::Serializer::Abstract->support_content_type('text/plain'),
        "text/plain is supported" );

    ok(
        Dancer::Serializer::Abstract->support_content_type(
            'text/plain; charset=utf8'),
        "text/plain; charset=utf8 is supported"
    );

    ok( !Dancer::Serializer::Abstract->support_content_type('application/json'),
        "application/json is not supported" );
}

SKIP: {
    Dancer::ModuleLoader->load($_) or skip "$_ is needed to run this test", 5
        for qw/ JSON YAML /;

    set serializer => 'Mutable';
    my $s = Dancer::Serializer->engine;

    my $tmpdir = File::Spec->tmpdir;

    %ENV = (
        'REQUEST_METHOD'    => 'GET',
        'HTTP_CONTENT_TYPE' => 'application/json',
        'HTTP_ACCEPT'       => 'text/xml',
        'HTTP_ACCEPT_TYPE'  => 'text/x-yaml',
        'PATH_INFO'         => '/',
        'TMPDIR'            => $tmpdir,
    );

    my $req = Dancer::Request->new( env => \%ENV );
    Dancer::SharedData->request($req);
    my $ct = Dancer::Serializer::Mutable::_request_content_types($req);
    is_deeply $ct, [ 'application/json' ];
    $ct = Dancer::Serializer::Mutable::_response_content_types($req);
    is_deeply $ct, [ 'text/xml', 'text/x-yaml', 'application/json' ];

    %ENV = (
        'REQUEST_METHOD' => 'PUT',
        'PATH_INFO'      => '/',
        'TMPDIR'         => $tmpdir,
    );
    $req = Dancer::Request->new( env => \%ENV );
    Dancer::SharedData->request($req);
    $ct = Dancer::Serializer::Mutable::_request_content_types($req);
    is_deeply $ct, ['application/json'];
    $ct = Dancer::Serializer::Mutable::_response_content_types($req);
    is_deeply $ct, ['application/json'];

    %ENV = (
        'REQUEST_METHOD' => 'PUT',
        'PATH_INFO'      => '/',
        'HTTP_ACCEPT'    => 'text/xml',
        'CONTENT_TYPE'   => 'application/json',
        'TMPDIR'         => $tmpdir,
    );
    $req = Dancer::Request->new( env => \%ENV );
    Dancer::SharedData->request($req);
    $ct = Dancer::Serializer::Mutable::_response_content_types($req);
    is_deeply $ct, [ 'text/xml', 'application/json' ];
}

# handler helper
SKIP: {
    skip 'JSON is needed to run this test', 3
      unless Dancer::ModuleLoader->load('JSON');

    my $body = '{"foo":42}';
    open my $in, '<', \$body;
    my $env = {
        CONTENT_LENGTH => length($body),
        CONTENT_TYPE   => Dancer::Serializer::JSON->content_type,
        REQUEST_METHOD => 'PUT',
        SCRIPT_NAME    => '/',
        'psgi.input'   => $in,
    };

    my $expected_params = { foo => '42', };

    # ---
    my $req = Dancer::Request->new( env => $env);
    is $req->body, $body, "body is untouched";

    my $processed_req = Dancer::Serializer->process_request($req);
    is_deeply( scalar( $processed_req->params('body') ),
        $expected_params, "body request has been deserialized" );
    is $processed_req->params->{'foo'}, 42, "params have been updated";

}
