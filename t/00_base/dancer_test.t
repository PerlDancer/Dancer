use Test::More import => ['!pass'];

use strict;
use warnings;

use Dancer ':syntax';
use Dancer::Test;
load_app 't::lib::TestApp';

# in t::lib::TestApp, we have 
# get '/' => sub { "Hello, this is the home" };

my $req = [GET => '/'];
my $false_req = [ GET => '/false/route' ];

route_exists $req;
route_doesnt_exist $false_req;

response_exists $req;
response_doesnt_exist $false_req;

response_status_is $req, 200;
response_status_isnt $req, 404;

response_content_is $req, "Hello, this is the home";
response_content_isnt $req, "foo bar";
response_content_is_deeply [GET => '/hash'], { a => 1, b => 2, c => 3};
response_content_like $req, qr{Hello};
response_content_unlike $req, qr{Goodbye};
response_headers_are_deeply [GET => '/with_headers'], [
    'X-Foo-Dancer' => 42,
    'Content-Type' => 'text/html',
    ];

my $resp = get_response($req);
is $resp->{status}, 200, "response status from get_response looks good";

$resp = dancer_response(@$req);
is $resp->{status}, 200, "response status from dancer_response looks good";

response_content_is [PUT => '/jsondata', { body => 42 }], 42,
    "a request with a body looks good";

response_content_is [POST => '/name', { params => {name => 'Bob'} }],
    "Your name: Bob", "a request with params looks good";

response_content_is
    [GET => '/headers_again', { headers => ['X-Foo-Dancer' => 55] }], 55,
    "a request with headers looks good";

done_testing;

