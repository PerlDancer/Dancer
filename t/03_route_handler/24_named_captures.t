use strict;
use warnings;
use Test::More import => ['!pass'], tests => 3;

use Dancer ':syntax';
use Dancer::Test;

# perl <= 5.8.x doesn't support named captures
plan skip_all => 'Need perl >= 5.10' if $] < 5.010;

my $route_regex = "/(?<class> user | content | post )/(?<action> delete | find )/(?<id> \\d+ )";

ok ( get( qr{
    $route_regex
  }x, sub { captures }
    ), 'first route set'
);

for my $test
(
    { path     => '/user/delete/234'
    , expected => {qw/ class user action delete id 234 /}
    }
) {
     my $handle;
     my $path = $test->{path};
     my $expected = $test->{expected};
     my $request = [GET => $path];

     response_exists $request;
     response_content_is_deeply $request, $expected;
}

