use strict;
use warnings;

use Test::More import => ['!pass'];
use Dancer ':syntax';
use Dancer::Test;

use Time::HiRes qw/gettimeofday/;

set serializer => 'JSON';

plan tests => 6;

ok(
    hook before_serializer => sub {
        my $response = shift;
        my (undef, $start) = gettimeofday;
        $response->content->{start_time} = $start;
    }
);

ok(
    hook after_serializer => sub {
        my $response = shift;
        like $response->content, qr/\"start_time\" :/;
    }
);

ok( get '/' => sub { { foo => 1 } } );

route_exists [ GET => '/' ];
response_content_like( [ GET => '/' ], qr/start_time/ );
