use Test::More import => ['!pass'], tests => 21;

use strict;
use warnings;

use Dancer ':syntax';
use Dancer::Test;
use File::Spec;

use lib File::Spec->catdir( 't', 'lib' );

load_app 'TestApp';

# in t::lib::TestApp, we have 
# get '/' => sub { "Hello, this is the home" };

my $req = [GET => '/'];
my $false_req = [ GET => '/false/route' ];

route_exists $req;
route_doesnt_exist $false_req;

response_status_is $req       => 200;
response_status_is $false_req => 404;

response_content_is   $req => "Hello, this is the home";
response_content_isnt $req => "foo bar";

response_content_is_deeply [GET => '/hash'] => { a => 1, b => 2, c => 3};

response_content_like   $req => qr{Hello};
response_content_unlike $req => qr{Goodbye};

response_headers_include [GET => '/with_headers'], [ 'Content-Type' => 'text/html' ];
response_headers_include [GET => '/with_headers'], [ 'X-Foo-Dancer' => '42' ];

my $resp = dancer_response(@$req);
is $resp->{status}, 200, "response status from dancer_response looks good";


response_content_is [POST => '/jsondata', { body => 42 }], 42,
    "a POST request with a body looks good";
response_content_is [PUT => '/jsondata', { body => 42 }], 42,
    "a PUT request with a body looks good";

response_content_is [POST => '/name', { params => {name => 'Bob'} }],
    "Your name: Bob", "a request with params looks good";

response_content_is
    [GET => '/headers_again', { headers => ['X-Foo-Dancer' => 55] }], 55,
    "a request with headers looks good";

response_content_is [
    POST => '/form',
    {
        headers => [ 'Content-Type' => 'application/x-www-form-urlencoded' ],
        body    => 'foo=bar'
    }
], 'bar', "a POST request with form urlencoded is ok";

note "capture logs"; {
    is setting("logger"), "capture";
    is setting("log"),    "debug";

    warning "Danger!  Warning!";
    debug   "I like pie.";

    is_deeply read_logs, [
        { level => "warning", message => "Danger!  Warning!" },
        { level => "debug",   message => "I like pie.", }
    ], "read_logs";

    error "Put out the light.";

    is_deeply read_logs, [
        { level => "error", message => "Put out the light." },
    ], "each read clears the trap";
}
