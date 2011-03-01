package main;
use strict;
use warnings;
use Test::More;

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
        'Set-Cookie' => 'a=b'
    ];
}
{
    note "Testing one cookie";
    my $req = [GET => '/set_two_cookies'];
    route_exists $req;
    response_headers_are_deeply $req, [
        'Content-Type' => 'text/html',
        'Set-Cookie' => 'a=b',
        'Set-Cookie' => 'c=d'
    ];
}

done_testing;
1;

