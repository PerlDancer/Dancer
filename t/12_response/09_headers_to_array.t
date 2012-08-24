package main;
use strict;
use warnings;
use Test::More tests => 3, import => ['!pass'];

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

# Dancer::Test::dancer_response does accept an HTTP::Headers object now (issue 755)
use HTTP::Headers;

my $res1 = dancer_response(GET => '/', { headers => HTTP::Headers->new('Content-Type' => 'text/ascii', 'XY' => 'Z')});
is($res1->header('Content-Type'), 'text/html', "Content-Type looks good for dancer_response accepting HTTP::Headers");

my $res2 = dancer_response(GET => '/', { headers => ['Content-Type' => 'text/ascii', 'XY' => 'Z']});

is_deeply($res1->headers_to_array, $res2->headers_to_array, "Headers look good for dancer_response accepting HTTP::Headers");


1;
