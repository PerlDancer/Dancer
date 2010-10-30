use strict;
use warnings;

use Test::More import => ['!pass'];
use Dancer::ModuleLoader;
use LWP::UserAgent;

binmode STDOUT, ':utf8';

plan skip_all => "Test::TCP is needed for this test"
    unless Dancer::ModuleLoader->load("Test::TCP");

plan tests => 3;

Test::TCP::test_tcp(
    client => sub {
        my $port = shift;
        my $res;
    
        $res = _get_http_response(GET => '/string', $port);
        is $res->content, "\x{1A9}", "response is unicode";

        $res = _get_http_response(GET => "/param/\x{1A9}", $port);
        is $res->content, "\x{1A9}", "response is unicode";
        
        $res = _get_http_response(GET => "/view", $port);
        is $res->content, "\x{1A9}", "response is unicode";
    },
    server => sub {
        my $port = shift;

        use Dancer;
        use t::lib::TestAppUnicode;

        setting charset => 'utf8';
        setting port => $port;
        setting access_log => 0;

        Dancer->dance();
    },
);


sub _get_http_response {
    my ($method, $path, $port) = @_;
    
    my $ua = LWP::UserAgent->new;

    my $req = HTTP::Request->new($method => "http://127.0.0.1:${port}${path}");
    return $ua->request($req);
}

