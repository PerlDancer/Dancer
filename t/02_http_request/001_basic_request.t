use Test::More import => ['!pass'];
use Dancer;

use lib 't';
use TestUtils;

eval "use LWP";
plan skip_all => "LWP is needed" if $@;

plan tests => 3;

my $port = 8888;
set port => $port;
set access_log => false;


get '/' => sub {
    "been here"
};

# start the Dancer in background
set daemon => true;
my $pid = Dancer->dance;
ok(defined($pid), "Dancer launched as a daemon ($pid)");

# tests real HTTP requests
my $res = http_request($port, GET => '/'); 
ok($res->is_success, "GET / is a success");

$res = http_request($port, 'POST' => '/');
ok(!$res->is_success, "POST / is not served");

# end, kill the Dancer
kill('TERM', $pid);
