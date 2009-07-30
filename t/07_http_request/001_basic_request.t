use Test::More 'no_plan', import => ['!pass'];
use Dancer;

my $port = 8888;
set port => $port;
set access_log => false;

sub http_request {
    my ($method, $path) = @_;
    my $url = "http://localhost:${port}${path}";
    my $lwp = LWP::UserAgent->new;
    my $req = HTTP::Request->new($method => $url);
    return $lwp->request($req);
}

eval "use LWP";
SKIP: {
    skip "LWP is needed", 2 if $@;

    get '/' => sub {
        "been here"
    };

    # start the Dancer in background
    set daemon => true;
    my $pid = Dancer->dance;
    ok(defined($pid), "Dancer launched as a daemon ($pid)");

    # tests real HTTP requests
    my $res = http_request(GET => '/'); 
    ok($res->is_success, "GET / is a success");

    $res = http_request('POST' => '/');
    ok(!$res->is_success, "POST / is not served");

    # end, kill the Dancer
    kill('TERM', $pid);
};
