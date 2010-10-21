use Test::More;
use strict;
use warnings;

use HTTP::Headers;
use Dancer::Headers;
use Dancer::ModuleLoader;
use HTTP::Headers;

plan tests => 7;

my ($dh, $headers);

$headers = ['Some-Header' => 42];
eval {
    $dh = Dancer::Headers->new(headers => $headers);
};
ok $@;
like $@, qr/unsupported headers: ARRAY/;

$headers = HTTP::Headers->new( 'Some-Header' => 42 );
$dh = Dancer::Headers->new( headers => $headers );
is $dh->get('Some-Header'), '42',
    "Dancer::Headers works with HTTP::Headers object";

ok(!$dh->get('Foo-Bar'), 'no header define for Foo-Bar');
$headers = HTTP::Headers->new('Some-Header' => 42);
$dh = Dancer::Headers->new(headers => $headers);
is $dh->get('Some-Header'), '42',
  "Dancer::Headers works with HTTP::Headers object";

is_deeply $dh->get_all, {'Some-Header' => 42}, "get_all works";
$headers->header('Other-Header' => 23);
$dh = Dancer::Headers->new(headers => $headers);
is_deeply $dh->get_all, {'Some-Header' => 42, 'Other-Header' => 23};
