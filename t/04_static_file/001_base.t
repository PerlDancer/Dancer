use strict;
use warnings;

# There is an issue with HTTP::Parser::XS while parsing an URI with \0
# Using the pure perl via PERL_ONLY works
BEGIN { $ENV{PERL_ONLY} = 1; }

use Test::More import => ['!pass'];
use Dancer::Test;


plan skip_all => "Skip test with Test::TCP in win32"
  if $^O eq 'MSWin32';
    
plan skip_all => "Test::TCP is required"
  unless Dancer::ModuleLoader->load('Test::TCP' => "1.13");

plan skip_all => "Plack is required"
  unless Dancer::ModuleLoader->load('Plack::Loader');

plan skip_all => "HTTP::Parser::XS is required"
  unless Dancer::ModuleLoader->load('HTTP::Parser::XS' => "0.10");

plan tests => 8;

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

ok $resp = Dancer::Test::_get_file_response( [ GET => "/hello\0.txt" ] );
my $r = Dancer::SharedData->response();
is $r->status,  400;
is $r->content, 'Bad Request';

require HTTP::Request;
require LWP::UserAgent;

Test::TCP::test_tcp(
    client => sub {
        my $port = shift;
        my $req =
          HTTP::Request->new(
            GET => "http://127.0.0.1:$port/hello%00.txt" );
        my $ua  = LWP::UserAgent->new();
        my $res = $ua->request($req);
        ok !$res->is_success;
        is $res->code, 400;
    },
    server => sub {
        my $port = shift;
        setting apphandler => 'PSGI';
        Dancer::Config->load;
        my $app = Dancer::Handler->psgi_app;
        Plack::Loader->auto( port => $port )->run($app);
        Dancer->dance();
    }
);
