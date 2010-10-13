use Test::More;
use strict;
use warnings;

use HTTP::Headers;
use Dancer::Headers;
use Dancer::ModuleLoader;

plan tests => 6;

my $headers = ['Some-Header' => 42];
my $dh = Dancer::Headers->new(headers => $headers);
is $dh->get('Some-Header'), '42', "Dancer::Headers works with arrayref";

is_deeply $dh->get_all, {'Some-Header' => 42}, "get_all works";

ok(!$dh->get('Foo-Bar'), 'no header define for Foo-Bar');
$headers = HTTP::Headers->new('Some-Header' => 42);
$dh = Dancer::Headers->new(headers => $headers);
is $dh->get('Some-Header'), '42',
  "Dancer::Headers works with HTTP::Headers object";

is_deeply $dh->get_all, {'Some-Header' => 42}, "get_all works";
$headers->header('Other-Header' => 23);
$dh = Dancer::Headers->new(headers => $headers);
is_deeply $dh->get_all, {'Some-Header' => 42, 'Other-Header' => 23};
