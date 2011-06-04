use strict;
use warnings;
use Test::More import => ['!pass'];

use Carp;
$Carp::Verbose = 1;

BEGIN {
    use Dancer::ModuleLoader;

    plan skip_all => "skip test with Test::TCP in win32" if $^O eq 'MSWin32';

    plan skip_all => 'Test::TCP is needed to run this test'
        unless Dancer::ModuleLoader->load('Test::TCP');
}

use Dancer;
use LWP::UserAgent;
use HTTP::Request;

plan tests => 1;

Test::TCP::test_tcp(
  client => sub {
      my $port = shift;
      my $url  = "http://127.0.0.1:$port/foo";
      my $ua  = LWP::UserAgent->new;
      my $res = $ua->post($url, { data => 'foo'});
      is($res->decoded_content, "data:foo");
  },
  server => sub {
      my $port = shift;
      Dancer::Config->load;
      post '/foo' => sub { forward '/bar';  };
      post '/bar' => sub { join(":",params) };
      setting startup_info => 0;
      setting port         => $port;
      setting show_errors  => 1;
      Dancer->dance();
  },
                   );

