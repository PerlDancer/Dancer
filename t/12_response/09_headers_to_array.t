package main;
use strict;
use warnings;
use Test::More tests => 1, import => ['!pass'];

{

    use Dancer;
    get '/' => sub {
        push_header A => 1;
        push_header A => 2;
        push_header B => 3;
    };
}

use Dancer::Test;

response_headers_include [GET => '/'] =>
  [ 'Content-Type' => 'text/html', 'A' => 1, 'A' => 2, 'B' => 3 ];

1;
