package main;
use strict;
use warnings;
use Test::More tests => 4, import => ['!pass'];

{
    use Dancer;
    get '/set_one_cookie' => sub {
        set_cookie "a" => "b";
    };
    get '/set_two_cookies' => sub {
        set_cookie "a" => "b";
        set_cookie "c" => "d";
    };
}

use Dancer::Test;


{
    note "Testing one cookie";
    my $req = [GET => '/set_one_cookie'];
    route_exists $req;
    response_headers_are_deeply $req, [
        'Content-Type' => 'text/html',
        'Set-Cookie' => 'a=b; path=/; HttpOnly'
    ];
}
{
    note "Testing two cookies";
    my $req = [GET => '/set_two_cookies'];
    route_exists $req;
    response_headers_are_deeply $req, [
        'Content-Type' => 'text/html',
        'Set-Cookie' => 'a=b; path=/; HttpOnly',
        'Set-Cookie' => 'c=d; path=/; HttpOnly',
    ];
}

1;

