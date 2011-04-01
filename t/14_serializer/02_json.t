use Test::More import => ['!pass'];
use strict;
use warnings;
use Dancer;

plan skip_all => "JSON is needed to run this tests"
    unless Dancer::ModuleLoader->load('JSON');
plan tests => 17;

set environment => 'testing';

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
my $json = $s->serialize($data, { pretty => 0 });
is $json, '{"foo":42}', "data is correctly serialized";
my $data2 = $s->deserialize($json);
is_deeply $data2, $data, "data is correctly deserialized";

# helpers

$json = to_json($data);
is $json, '{"foo":42}',
  "data is correctly serialized";

$data2 = from_json($json);
is_deeply($data2, $data, "data is correctly deserialized");

$data = {foo => {bar => {baz => [qw/23 42/]}}};
$json = to_json($data, {pretty => 1});
like $json, qr/"foo" : {/, "data is pretty!";
$data2 = from_json($json);
is_deeply($data2, $data, "data is correctly deserialized");

my $config = {
    engines => {
        JSON => {
            allow_blessed   => 1,
            convert_blessed => 1,
            pretty          => 0,
        }
    }
};

ok $s = Dancer::Serializer->init( 'JSON', $config ),
  'JSON serializer with custom config';
$data = { foo => 'bar' };
my $res = $s->serialize($data);
is_deeply( $data, JSON::decode_json($res), 'data is correctly serialized' );

# XXX tests for deprecation
my $warn;
local $SIG{__WARN__} = sub { $warn = $_[0] };
$s->_options_as_hashref(foo => 'bar');
ok $warn, 'deprecation warning';
undef $warn;

$s->_options_as_hashref({foo => 'bar'});
ok !$warn, 'no deprecation warning';

to_json({foo => 'bar'}, indent => 0);
ok $warn, 'deprecation warning';
