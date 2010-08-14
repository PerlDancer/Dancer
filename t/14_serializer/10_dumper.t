use Test::More import => ['!pass'];
use strict;
use warnings;
use Dancer;

ok(setting('serializer' => 'Dumper'), "serializer Dumper loaded");
my $s = Dancer::Serializer->engine;

isa_ok($s, $_) for qw(
    Dancer::Engine
    Dancer::Serializer::Abstract
    Dancer::Serializer::Dumper);
can_ok $s, qw(serialize deserialize);

my $data = { foo => 42 };
my $dumper = $s->serialize($data);
like $dumper, qr/'foo' => 42/, "data is correctly serialized by \$s";
like Dancer::to_dumper($data), qr/'foo' => 42/, 
    "data is correctly serialized by to_dumper()";

my $data2 = $s->deserialize($dumper);
is_deeply $data2, $data, 
    "data is correctly deserialized by \$s";
is_deeply Dancer::from_dumper($dumper), $data, 
    "data is correctly deserialized by from_dumper";

is $s->content_type, 'text/x-data-dumper',
    "content_type is text/x-data-dumper";

done_testing;
