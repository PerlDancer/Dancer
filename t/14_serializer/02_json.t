use Test::More;
use strict;
use warnings;
use Dancer::Config 'setting';

plan skip_all => "JSON is needed to run this tests"
    unless Dancer::ModuleLoader->load('JSON');
plan tests => 8;

eval { 
    setting serializer => 'FooBar';
};
like $@, qr/unknown serializer engine 'FooBar', perhaps you need to install Dancer::Serializer::FooBar/,
    "Foobar is not a valid serializer";

ok(setting('serializer' => 'JSON'), "serializer JSON loaded");
my $s = Dancer::Serializer->engine;

isa_ok($s, $_) for qw(
    Dancer::Engine
    Dancer::Serializer::Abstract
    Dancer::Serializer::JSON);
can_ok $s, qw(serialize deserialize);

my $data = { foo => 42 };
my $json = $s->serialize($data);
is $json, '{"foo":42}', "data is correctly serialized";
my $data2 = $s->deserialize($json);
is_deeply $data2, $data, "data is correctly deserialized";

