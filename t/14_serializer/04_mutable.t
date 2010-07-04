use Test::More import => ['!pass'];
use strict;
use warnings;
use Dancer;

plan tests => 5;

ok(setting('serializer' => 'Mutable'), "serializer Mutable loaded");
my $s = Dancer::Serializer->engine;

isa_ok($s, $_) for qw(
    Dancer::Engine
    Dancer::Serializer::Abstract
    Dancer::Serializer::Mutable);
can_ok $s, qw(serialize deserialize);
