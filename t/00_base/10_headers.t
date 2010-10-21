use Test::More;
use strict;
use warnings;

use Dancer::Headers;
use Dancer::ModuleLoader;
use HTTP::Headers;

plan tests => 4;

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

is_deeply $dh->get_all, { 'Some-Header' => 42 }, "get_all works";

