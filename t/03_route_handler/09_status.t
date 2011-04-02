use Test::More import => ['!pass'];

use strict;
use warnings;

use Dancer ':syntax';
use Dancer::Test;

get '/' => sub { 1 };

my @tests = (
    [ 'GET', '/', '200'],
);
plan tests => scalar(@tests);

foreach my $test (@tests) {
    my ($method, $path, $expected) = @$test;
    response_status_is [$method => $path] => $expected, 
      "status looks good for $method $path";
}

