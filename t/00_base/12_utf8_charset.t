use strict;
use warnings;

use Test::More import => ['!pass'];

use LWP::UserAgent;
use HTTP::Request;
use Dancer::ModuleLoader;
use Dancer::Request;
use Dancer;
use File::Spec;

plan skip_all => 'Plack::Test is needed for this test'
    unless Dancer::ModuleLoader->load('Plack::Test');

plan skip_all => "Test::TCP is needed for this test"
    unless Dancer::ModuleLoader->load("Test::TCP");

plan skip_all => "Plack::Test is needed for this test"
    unless Dancer::ModuleLoader->load("Plack::Test");

my @templates = qw(simple);

push @templates, 'template_toolkit' if Dancer::ModuleLoader->load('Template');
push @templates, 'tiny' if Dancer::ModuleLoader->load('Dancer::Template::Tiny');

my @plack_servers = qw(plackup);
push @plack_servers, 'Starman' if Dancer::ModuleLoader->load('Starman');

plan tests => scalar(@templates) * scalar(@plack_servers);

my $app = sub {
    my $env = shift;
    
    setting views => File::Spec->rel2abs(path(dirname(__FILE__)));
    setting apphandler  => 'PSGI';
    setting show_errors => 1;
    setting access_log  => 0;
    setting charset => 'utf8';

    get '/' => sub { template 'test' };

    my $request = Dancer::Request->new($env);
    Dancer->dance($request);
};

for my $plack (@plack_servers) {

    $ENV{PLACK_SERVER} = $plack;

    for my $template (@templates) {

        setting template    => $template;
        
        Plack::Test::test_psgi($app, sub {
            my $cb = shift;

            my $req = HTTP::Request->new(GET => "/");
            my $res = $cb->($req);

            # Test!
            is $res->content, "This is utf8: ’♣ ♤ ♥ ♦’\n",
               "PSGI/$plack template/$template : UTF-8 string is rendered correctly";
        });
    }
}

