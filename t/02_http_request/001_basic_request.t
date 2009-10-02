use Test::More import => ['!pass'];
use Dancer;

use lib 't';
use TestUtils;

eval "use LWP";
plan skip_all => "LWP is needed" if $@;

plan tests => 7;

my $port = 8888;
set port => $port;
set access_log => false;

get '/' => sub { "been here" };
get '/error' => sub { send_error "foo" };

# start the Dancer in background
set daemon => true;
my $pid = Dancer->dance;
ok(defined($pid), "Dancer launched as a daemon ($pid)");

# tests real HTTP requests
my $res = http_request($port, GET => '/'); 
ok($res->is_success, "GET / is a success");
is($res->status_line, '200 OK', 
    'status line looks good for GET /');

$res = http_request($port, 'POST' => '/');
ok(!$res->is_success, "POST / is not served");
is($res->status_line, '404 Not found', 
    'status line looks good for POST /');

$res = http_request($port, 'GET' => '/error');
ok(!$res->is_success, "GET /error sends an error code");
is($res->status_line, '500 Internal Server Error', 
    'status line looks good for GET /error');


# end, kill the Dancer
kill('TERM', $pid);
