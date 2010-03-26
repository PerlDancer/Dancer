use Test::More;
use strict;
use warnings;
use Dancer::Config 'setting';

plan skip_all => "YAML needed to run this tests"
    unless Dancer::ModuleLoader->load('YAML');
plan tests => 7;

ok(setting('serializer' => 'YAML'), "serializer YAML loaded");
my $s = Dancer::Serializer->engine;

isa_ok($s, $_) for qw(
    Dancer::Engine
    Dancer::Serializer::Abstract
    Dancer::Serializer::YAML);
can_ok $s, qw(serialize deserialize);

my $data = { foo => 42 };
my $yaml = $s->serialize($data);
like $yaml, qr/foo: 42/, "data is correctly serialized";
my $data2 = $s->deserialize($yaml);
is_deeply $data2, $data, "data is correctly deserialized";

