use Test::More import => ['!pass'];
use strict;
use warnings;
use Dancer;

plan tests => 7;

ok(setting('serializer' => 'Dumper'), "serializer Dumper loaded");
my $s = Dancer::Serializer->engine;

isa_ok($s, $_) for qw(
    Dancer::Engine
    Dancer::Serializer::Abstract
    Dancer::Serializer::Dumper);
can_ok $s, qw(serialize deserialize);

my $data = { foo => 42 };
my $dumper = $s->serialize($data);
like $dumper, qr/'foo' => 42/, "data is correctly serialized";
my $data2 = $s->deserialize($dumper);
is_deeply $data2, $data, "data is correctly deserialized";

