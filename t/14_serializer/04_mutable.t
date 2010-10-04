use Test::More import => ['!pass'];

use strict;
use warnings;
use Dancer;

BEGIN {
    plan skip_all => 'YAML is needed to run this test'
        unless Dancer::ModuleLoader->load('YAML');
    plan skip_all => 'JSON is needed to run this test'
        unless Dancer::ModuleLoader->load('JSON');
}

plan tests => 14;

ok(setting('serializer' => 'Mutable'), "serializer Mutable loaded");
my $s = Dancer::Serializer->engine;

isa_ok($s, $_) for qw(
  Dancer::Engine
  Dancer::Serializer::Abstract
  Dancer::Serializer::Mutable);
can_ok $s, qw(serialize deserialize);

ok !defined $s->content_type, 'no content_type defined';

ok $s->support_content_type('application/json'),
  'application/json is a supported content_type';

ok !$s->support_content_type('foo/bar'),
  'foo/bar is not a supported content_type';

my $request = Dancer::Request->new_for_request('GET', '/',);
Dancer::SharedData->request($request);

my $data = {foo => 42};
ok my $result = $s->serialize($data), 'got result from serialize';
like $result, qr/{"foo":42}/, 'result is correct';

is $s->content_type, 'application/json', 'correct content_type';

$result = $s->deserialize($result, $request);
is_deeply($result, $data, 'got same result');

%ENV = (
    'REQUEST_METHOD' => 'GET',
    'REQUEST_URI' => '/',
    'PATH_INFO' => '/',
    'QUERY_STRING' => 'foo=bar&number=42',
    'HTTP_ACCEPT_TYPE' => 'text/x-yaml',
);

my $req = Dancer::Request->new(\%ENV);
Dancer::SharedData->request($req);
eval { $s->deserialize($data) };
ok $@, 'died okay';

$result = $s->serialize($data);
is $s->content_type, 'text/x-yaml', 'correct content_type';
