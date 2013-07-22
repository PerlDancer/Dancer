use Test::More import => ['!pass'];
use strict;
use warnings;
use Dancer ':tests';

plan tests => 53;

my $struct = {eris => 23};

{
    # test an unknown serializer
    eval { setting serializer => 'FooBar'; };
    like $@,
      qr/unable to load serializer engine 'FooBar'/,
      "Foobar is not a valid serializer";
}

SKIP: {
    skip 'YAML is needed to run this test', 10
      unless Dancer::ModuleLoader->load('YAML');

    # helpers syntax
    ok my $test         = to_yaml($struct), 'to yaml';
    ok my $final_struct = from_yaml($test), 'from yaml';
    is_deeply $final_struct, $struct, 'from => to works';

    # OO API
    setting('serializer' => 'YAML');
    my $s = Dancer::Serializer->engine;

    isa_ok( $s, $_ ) for qw(
      Dancer::Engine
      Dancer::Serializer::Abstract
      Dancer::Serializer::YAML);
    can_ok $s, qw(serialize deserialize);

    my $yaml = $s->serialize($struct);
    like $yaml, qr/eris: 23/, "data is correctly serialized";
    my $data = $s->deserialize($yaml);
    is_deeply $struct, $data, "data is correctly deserialized";

    is $s->content_type, 'text/x-yaml', "content_type is ok";
}

SKIP: {
    skip 'JSON is needed to run this test', 14
      unless Dancer::ModuleLoader->load_with_params('JSON', '-support_by_pp');

    # helpers syntax
    ok my $test         = to_json($struct), 'to json';
    ok my $final_struct = from_json($test), 'from json';
    is_deeply $final_struct, $struct, 'from => to works';

    # OO API
    setting( 'serializer' => 'JSON' );
    my $s = Dancer::Serializer->engine;
    isa_ok( $s, $_ ) for qw(
      Dancer::Engine
      Dancer::Serializer::Abstract
      Dancer::Serializer::JSON);
    can_ok $s, qw(serialize deserialize);

    my $json = $s->serialize( $struct, { pretty => 0 } );
    is $json, '{"eris":23}', "data is correctly serialized";
    my $data = $s->deserialize($json);
    is_deeply $data, $struct, "data is correctly deserialized";

    # with options
    $data = { foo => { bar => { baz => [qw/23 42/] } } };
    $json = to_json( $data, { pretty => 1 } );
    like $json, qr/"foo" : \{/, "data is pretty!";
    my $data2 = from_json($json);
    is_deeply( $data2, $data, "data is correctly deserialized" );

    # configure JSON parser
    my $config = {
        engines => {
            JSON => {
                allow_blessed   => 1,
                convert_blessed => 1,
                pretty          => 0,
                escape_slash    => 1
            }
        }
    };

    ok $s = Dancer::Serializer->init( 'JSON', $config ),
      'JSON serializer with custom config';
    $data = { foo => '/bar' };
    my $res = $s->serialize($data);
    is_deeply( $data, JSON::decode_json($res), 'data is correctly serialized' );

    ok($res =~m|\\/|, 'JSON serializer obeys config options to init');

    # # XXX tests for deprecation
    # my $warn;
    # local $SIG{__WARN__} = sub { $warn = $_[0] };
    # $s->_options_as_hashref( foo => 'bar' );
    # ok $warn, 'deprecation warning';
    # undef $warn;

    # $s->_options_as_hashref( { foo => 'bar' } );
    # ok !$warn, 'no deprecation warning';

    # to_json( { foo => 'bar' }, { indent => 0 } );
    # ok $warn, 'deprecation warning';
}

SKIP: {
    skip 'XML::Simple is needed to run this test', 13
      unless Dancer::ModuleLoader->load('XML::Simple');

    skip 'XML::Parser or XML::SAX are needed to run this test', 13
        unless Dancer::ModuleLoader->load('XML::Parser') or
               Dancer::ModuleLoader->load('XML::SAX');

    # helpers
    ok my $test         = to_xml($struct), 'to xml';
    ok my $final_struct = from_xml($test), 'from xml';
    is_deeply $final_struct, $struct, 'from => to works';

    my $xml = to_xml($struct, RootName => undef);
    like $xml, qr/<eris>23<\/eris>/, "data is correctly serialized";

    my $data = from_xml($xml);
    is $data, 23, "data is correctly deserialized";

    $data = {
        task => {
            type     => "files",
            continue => 1,
            action   => 123,
            content  => '46210660-b78f-11df-8d81-0800200c9a66',
            files    => { file => [2131231231] }
        },
    };

    $xml = to_xml($data, RootName => undef, AttrIndent => 1);
    like $xml, qr/\n\s+\w+="\w+">46210660-b78f-11df-8d81-0800200c9a66<files>/, 'xml attributes are indented';

    # OO API
    setting( 'serializer' => 'XML' );
    my $s = Dancer::Serializer->engine;

    isa_ok( $s, $_ ) for qw(
      Dancer::Engine
      Dancer::Serializer::Abstract
      Dancer::Serializer::XML);
    can_ok $s, qw(serialize deserialize);

    $xml = $s->serialize($struct);
    like $xml, qr/eris="23"/, "data is correctly serialized";
    $data = $s->deserialize($xml);
    is_deeply $struct, $data, "data is correctly deserialized";

    is $s->content_type, 'text/xml', 'content type is ok';
}

SKIP: {
    skip 'YAML is needed to run this test', 7
      unless Dancer::ModuleLoader->load('YAML');

    skip 'JSON is needed to run this test', 7
      unless Dancer::ModuleLoader->load('JSON');

    setting( 'serializer' => 'Mutable' );
    my $s = Dancer::Serializer->engine;

    isa_ok( $s, $_ ) for qw(
      Dancer::Engine
      Dancer::Serializer::Abstract
      Dancer::Serializer::Mutable);
    can_ok $s, qw(serialize deserialize);

    ok !defined $s->content_type, 'no content_type defined';

    ok $s->support_content_type('application/json'),
        'application/json is a supported content_type';

    ok !$s->support_content_type('foo/bar'),
        'foo/bar is not a supported content_type';
}

{
    setting( 'serializer' => 'Dumper' );
    my $s = Dancer::Serializer->engine;

    isa_ok( $s, $_ ) for qw(
      Dancer::Engine
      Dancer::Serializer::Abstract
      Dancer::Serializer::Dumper);
    can_ok $s, qw(serialize deserialize);

    my $dumper = $s->serialize($struct);
    like $dumper, qr/'eris' => 23/, "data is correctly serialized by \$s";
    like to_dumper($struct), qr/'eris' => 23/,
      "data is correctly serialized by to_dumper()";

    my $data = $s->deserialize($dumper);
    is_deeply $data, $struct, "data is correctly deserialized by \$s";

    is $s->content_type, 'text/x-data-dumper',
      "content_type is text/x-data-dumper";
}
