use strict;
use warnings;
use Test::More import => ['!pass'];

use Dancer ':syntax';
use Dancer::Test;

plan tests => 2;

SKIP: {
    skip "Need perl >= 5.10", 2 unless $] >= 5.010;

    my $route_regex =
      "/(?<class> user | content | post )/(?<action> delete | find )/(?<id> \\d+ )";

    get qr{$route_regex}x => sub {captures};

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
        response_status_is         $request => 200;
        response_content_is_deeply $request => $expected;
    }
}

# perl <= 5.8.x doesn't support named captures
#plan skip_all => 'Need perl >= 5.10' if $] < 5.010;

