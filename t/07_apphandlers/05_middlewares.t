use Test::More import => ['!pass'];
use strict;
use warnings;

use Dancer ':syntax';
use Dancer::ModuleLoader;
use LWP::UserAgent;

use File::Spec;
use lib File::Spec->catdir( 't', 'lib' );

plan skip_all => "Test::TCP is needed for this test"
  unless Dancer::ModuleLoader->load("Test::TCP");
plan skip_all => "Plack is needed to run this test"
  unless Dancer::ModuleLoader->load('Plack::Request');

Dancer::ModuleLoader->load('Plack::Loader');

my $confs = [ [ [ ['Runtime'] ] ] ];

plan tests => (2 * scalar @$confs);


foreach my $c (@$confs) {
    Test::TCP::test_tcp(
        client => sub {
            my $port = shift;
            my $ua   = LWP::UserAgent->new;

            my $req = HTTP::Request->new( GET => "http://localhost:$port/" );
            my $res = $ua->request($req);
            ok $res;
            ok $res->header('X-Runtime');
        },
        server => sub {
            my $port = shift;

            use TestApp;
            Dancer::Config->load;

            setting environment       => 'production';
            setting apphandler        => 'PSGI';
            setting port              => $port;
            setting startup_info      => 0;
            setting plack_middlewares => $c->[0];
            my $app = Dancer::Handler->get_handler()->dance;
            Plack::Loader->auto( port => $port )->run($app);
        },
    );

}
