use strict;
use warnings;
use Test::More import => ['!pass'];

use Dancer ':syntax';
use Dancer::Test;

plan tests => 3;

SKIP: {
    skip "Need perl >= 5.10", 3 unless $] >= 5.010;

    my $route_regex =
      "/(?<class> user | content | post )/(?<action> delete | find )/(?<id> \\d+ )";

    ok(get(qr{ $route_regex }x, sub {captures}), 'first route set');

    for my $test (
        {   path     => '/user/delete/234',
            expected => {qw/ class user action delete id 234 /}
        }
      )
    {
        my $handle;
        my $path     = $test->{path};
        my $expected = $test->{expected};
        my $request  = [GET => $path];

        response_exists $request;
        response_content_is_deeply $request, $expected;
    }
}
