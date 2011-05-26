use strict;
use warnings;

use Test::More tests => 8, import => ['!pass'];
use Dancer::Test;

use Dancer ':syntax';

set public => path( dirname(__FILE__), 'static' );
my $public = setting('public');

my $req = [ GET => '/hello.txt' ];
response_is_file $req;

my $resp = Dancer::Test::_get_file_response($req);
is_deeply(
    $resp->headers_to_array,
    [ 'Content-Type' => 'text/plain' ],
    "response header looks good for @$req"
);
is( ref( $resp->{content} ), 'GLOB', "response content looks good for @$req" );

$resp = Dancer::Test::_get_file_response([ GET => "/hello\0.txt" ]);
ok $resp;
my $r = Dancer::SharedData->response();
is $r->status, 400;
is $r->content, 'Bad Request';

SKIP: {
    skip "Test::TCP is required", 1 unless Dancer::ModuleLoader->load('Test::TCP');
    use HTTP::Request;
    use LWP::UserAgent;
    use Plack::Loader;
    Test::TCP::test_tcp(
        client => sub {
            my $port = shift;
            my $req = HTTP::Request->new(GET => "http://127.0.0.1:$port/hello%00.txt");
            my $ua = LWP::UserAgent->new();
            my $res = $ua->request($req);
            ok !$res->is_success;
            is $res->code, 400;
        },
        server => sub {
            my $port = shift;
            setting apphandler => 'PSGI';
            get '/' => sub {"hello"};
            Dancer::Config->load;
            my $app = Dancer::Handler->psgi_app;
            Plack::Loader->auto(port => $port)->run($app);
            Dancer->dance();
        }
    );
};
