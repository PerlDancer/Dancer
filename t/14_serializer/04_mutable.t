use Test::More import => ['!pass'];
use Test::Exception;

use strict;
use warnings;
use Dancer;

BEGIN {
    plan skip_all => 'YAML is needed to run this test'
        unless Dancer::ModuleLoader->load('YAML');
    plan skip_all => 'JSON is needed to run this test'
        unless Dancer::ModuleLoader->load('JSON');
}

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
ok my $result = $s->serialize($data);
like $result, qr/{"foo":42}/;

is $s->content_type, 'application/json';

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

dies_ok {$s->deserialize($data)};

$result = $s->serialize($data);
is $s->content_type, 'text/x-yaml';

done_testing;
