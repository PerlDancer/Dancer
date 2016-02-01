use strict;
use warnings;
no warnings 'uninitialized';

use Test::More qw(no_plan);

use HTTP::Headers;

use Dancer::Request;

my $headers = HTTP::Headers->new;
$headers->header('Content-Type' => 'application/json');
$headers->header('Accept' => 'application/json');
my $json_string = '{"json_thing":"whatever"}';
my $request = Dancer::Request->new_for_request(
    PATCH => '/some/url/or/another',
    undef, $json_string, $headers,
    {
        CONTENT_TYPE => 'application/json',
        HTTP_ACCEPT => 'application/json',
        REQUEST_URI => '/some/url/or/another',
    }
);

is($request->body, $json_string);

