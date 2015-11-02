use strict;
use warnings;
use Test::More import => ['!pass'];

use Carp;
$Carp::Verbose = 1;

BEGIN {
    use Dancer::ModuleLoader;

    plan skip_all => "skip test with Test::TCP in win32" if $^O eq 'MSWin32';

    plan skip_all => 'Test::TCP is needed to run this test'
        unless Dancer::ModuleLoader->load('Test::TCP' => "1.30");
}

use Dancer;
use LWP::UserAgent;
use HTTP::Request;

plan tests => 2;

Test::TCP::test_tcp(
  client => sub {
      my $port = shift;
      my $url_base  = "http://127.0.0.1:$port";
      my $ua  = LWP::UserAgent->new;
      my $res = $ua->post($url_base . "/foo", { data => 'foo'});
      is($res->decoded_content, "data:foo");

      $res = $ua->post($url_base . "/foz", { data => 'foo'});
      is($res->decoded_content, "data:foo");
  },
  server => sub {
      my $port = shift;
      Dancer::Config->load;
      post '/foo' => sub {
          forward '/bar';
          fail "This line should not be executed - forward should have aborted the route execution";
      };
      post '/bar' => sub { join(":",params) };

      post '/foz' => sub { forward '/baz';  };
      post '/baz' => sub { join(":",params('body')) };
      set startup_info => 0, port => $port, server => '127.0.0.1', show_errors  => 1;
      Dancer->dance();
  },
                   );

