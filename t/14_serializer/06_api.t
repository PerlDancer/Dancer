use Test::More import => ['!pass'];
use strict;
use warnings;

use Dancer ':tests';
use Dancer::Request;
use Dancer::Serializer;
use Dancer::Serializer::Abstract;

plan tests => 13;

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

{
    skip 'JSON is needed to run this test', 3
      unless Dancer::ModuleLoader->load('JSON');
    skip 'YAML is needed to run this test', 3
      unless Dancer::ModuleLoader->load('YAML');

    setting('serializer' => 'Mutable');
    my $s = Dancer::Serializer->engine;

    %ENV = (
        'REQUEST_METHOD'    => 'GET',
        'HTTP_CONTENT_TYPE' => 'application/json',
        'HTTP_ACCEPT'       => 'text/xml',
        'HTTP_ACCEPT_TYPE'  => 'text/x-yaml',
        'PATH_INFO'         => '/',
    );

    my $req = Dancer::Request->new( \%ENV );
    Dancer::SharedData->request($req);
    my $ct = $s->_find_content_type($req);
    is_deeply $ct, [ 'text/xml', 'text/x-yaml', 'application/json' ];

    %ENV = (
        'REQUEST_METHOD' => 'PUT',
        'PATH_INFO'      => '/',
    );
    $req = Dancer::Request->new( \%ENV );
    Dancer::SharedData->request($req);
    $ct = $s->_find_content_type($req);
    is_deeply $ct, ['application/json'];

    %ENV = (
        'REQUEST_METHOD' => 'PUT',
        'PATH_INFO'      => '/',
        'HTTP_ACCEPT'    => 'text/xml',
        'CONTENT_TYPE'   => 'application/json',
    );
    $req = Dancer::Request->new( \%ENV );
    Dancer::SharedData->request($req);
    $ct = $s->_find_content_type($req);
    is_deeply $ct, [ 'application/json', 'text/xml' ];
}
