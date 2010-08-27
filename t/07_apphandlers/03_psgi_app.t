use Test::More import => ['!pass'];
use strict;
use warnings;
use Dancer::ModuleLoader;

plan skip_all => "Plack is needed to run this test"
    unless Dancer::ModuleLoader->load('Plack::Request');
plan skip_all => "LWP is needed to run this test"
    unless Dancer::ModuleLoader->load('LWP::UserAgent');
plan skip_all => "Test::TCP is needed to run this test"
    unless Dancer::ModuleLoader->load('Test::TCP');

Dancer::ModuleLoader->load('Plack::Loader');

my $app = sub {
    my $env = shift;
    my $request = Dancer::Request->new($env);
    Dancer->dance($request);
};

plan tests => 5;

Test::TCP::test_tcp(
    client => sub {
        my $port = shift;
        my $ua = LWP::UserAgent->new;

        my $res = $ua->get("http://127.0.0.1:$port/env");
        like $res->content, qr/psgi\.version/,
            'content looks good for /env';

        $res = $ua->get("http://127.0.0.1:$port/name/bar");
        like $res->content, qr/Your name: bar/,
            'content looks good for /name/bar';

        $res = $ua->get("http://127.0.0.1:$port/name/baz");
        like $res->content, qr/Your name: baz/,
            'content looks good for /name/baz';
    },
    server => sub {
        my $port = shift;

        use t::lib::TestApp;
        use Dancer;
        setting apphandler  => 'PSGI';
        setting environment => 'production';
        Dancer::Config->load;

        Plack::Loader->auto(port => $port)->run($app);
    },
);

# test D::H::PSGI interface

Dancer::ModuleLoader->require('Dancer::Handler::PSGI');

my %ENV = (
    METHOD          => 'GET',
    PATH            => '/',
    HTTP_ACCEPT     => 'text/html',
    HTTP_USER_AGENT => 'test::more',
);

my $handler = Dancer::Handler::PSGI->new();
$handler->init_request_headers(\%ENV);
ok my $headers = Dancer::SharedData->headers;
isa_ok $headers->{_headers}, 'HTTP::Headers';
