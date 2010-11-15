use Test::More import => ['!pass'];
use strict;
use warnings;
use Dancer;

plan skip_all => "XML::Simple is needed to run this tests"
    unless Dancer::ModuleLoader->load('XML::Simple');

plan skip_all => "XML::Parser or XML::SAX are needed to run this tests"
    unless Dancer::ModuleLoader->load('XML::Parser') or
           Dancer::ModuleLoader->load('XML::SAX');

plan tests => 13;

ok(setting('serializer' => 'XML'), "serializer XML loaded");
my $s = Dancer::Serializer->engine;

isa_ok($s, $_) for qw(
    Dancer::Engine
    Dancer::Serializer::Abstract
    Dancer::Serializer::XML);

can_ok $s, qw(serialize deserialize);

my $data = { foo => 42 };
my $xml = $s->serialize($data);
like $xml, qr/foo="42"/, "data is correctly serialized";
my $data2 = $s->deserialize($xml);
is_deeply $data2, $data, "data is correctly deserialized";

is $s->content_type, 'text/xml', 'content type is ok';

# helpers

$xml = to_xml($data);
like $xml, qr/opt foo="42"/, "data is correctly serialized";

$data2 = from_xml($xml);
is_deeply $data, {foo => 42}, "data is correctly deserialized";

$xml = to_xml($data, RootName => undef);
like $xml, qr/<foo>42<\/foo>/, "data is correctly serialized";

$data2 = from_xml($xml);
is $data2, 42, "data is correctly serialized";

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
like $xml, qr/type="files">46210660-b78f-11df-8d81-0800200c9a66<files>/, 'xml attributes are indented';
