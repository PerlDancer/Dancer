use Test::More import => ['!pass'];
use lib 't';
use TestUtils;

eval "use LWP::UserAgent";
plan skip_all => "LWP is needed to test HTTP requests" if $@;

my @tests = (
    {method => 'GET', path => '/',
     expected => {
        status => '200 OK', 
        content => qr/body/} },
    {method => 'HEAD', path => '/',
     expected => {
        status => '200 OK', 
        content => qr/^\s*$/} },

);

plan tests => 1 + scalar(@tests) * 3;

use Dancer;
get '/' => sub {
    "body";
};

# start the Dancer in background
set daemon => true;
set port => 3000;
set access_log => false;
my $pid = dance;
ok(defined($pid), "Dancer launched as a daemon ($pid)");

foreach my $t (@tests) {
    my $res = http_request(3000, $t->{method}, $t->{path});
    ok( $res->is_success, 
    "request ".$t->{method}." ".$t->{path}." is a success");
    is($res->status_line, $t->{expected}{status}, "status looks good");
    like($res->content, $t->{expected}{content}, "response looks good");
}

kill('TERM', $pid);
