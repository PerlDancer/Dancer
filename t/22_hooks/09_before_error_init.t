use strict;
use warnings;
use lib '../../lib';
use Test::More import => ['!pass'];
use Dancer ':syntax';
use Dancer::Test;

plan tests => 3;

get '/' => sub {
    die 'ouch!';
};

route_exists [ GET => '/' ];
response_status_is( [ GET => '/' ], 500 );

hook before_error_init => sub {
    my $error = shift;
    $error->{code} = 555;
    $error->{title} = 'foo';
    $error->{message} = 'bar';
};

response_status_is( [ GET => '/' ], 555 );

