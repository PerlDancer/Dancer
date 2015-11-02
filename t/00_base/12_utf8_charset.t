use strict;
use warnings;

use utf8;
use Encode;
use Test::More import => ['!pass'];
use Dancer::ModuleLoader;
use LWP::UserAgent;

plan skip_all => "skip test with Test::TCP in win32/cygwin" if ($^O eq 'MSWin32' or $^O eq 'cygwin');
plan skip_all => "Test::TCP is needed for this test"
    unless Dancer::ModuleLoader->load("Test::TCP" => '1.30');

plan tests => 4;

Test::TCP::test_tcp(
    client => sub {
        my $port = shift;
        my $res;

        $res = _get_http_response(GET => '/string', $port);
        is d($res->content), "\x{1A9}", "utf8 static response";

        $res = _get_http_response(GET => '/other/string', $port);
        is d($res->content), "\x{1A9}", "utf8 response through forward";

        $res = _get_http_response(GET => "/param/".u("\x{1A9}"), $port);
        is d($res->content), "\x{1A9}", "utf8 route param";

        $res = _get_http_response(GET => "/view?string1=".u("\x{E9}"), $port);
        is d($res->content), "sigma: 'Ʃ'\npure_token: 'Ʃ'\nparam_token: '\x{E9}'\n",
            "params and tokens are valid unicode";
    },
    server => sub {
        my $port = shift;

        use Dancer;
        use t::lib::TestAppUnicode;

        set( charset      => 'utf8',
             host         => '127.0.0.1',
             port         => $port,
             show_errors  => 1,
             startup_info => 0,
             log          => 'debug',
             logger       => 'console');

        Dancer->dance();
    },
);

sub u {
    encode('UTF-8', $_[0]);
}

sub d {
    decode('UTF-8', $_[0]);
}

sub _get_http_response {
    my ($method, $path, $port) = @_;

    my $ua = LWP::UserAgent->new;
    my $req = HTTP::Request->new($method => "http://127.0.0.1:$port${path}");
    return $ua->request($req);
}

