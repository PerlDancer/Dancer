use strict;
use warnings;
use Test::More import => ['!pass'];
use Dancer::ModuleLoader;

plan skip_all => "Test::Output is needed for this test"
    unless Dancer::ModuleLoader->load("Test::Output");

plan tests => 4;

use Dancer;

set startup_info => false, apphandler   => 'Debug';

get '/' => sub { 42 };
get '/env' => sub { request->env->{HTTP_X_REQUESTED_WITH} };

my $handler = Dancer::Handler->get_handler;
isa_ok $handler, 'Dancer::Handler::Debug';

@ARGV = (GET => '/', 'foo=42');
my $psgi;
Test::Output::stdout_like
  (
   sub { $psgi = Dancer->start },
   qr{X-Powered-By: Perl Dancer.*42}sm, 
   "output looks good"
  );

is $psgi->[0], 200, "psgi response is ok";

subtest "env variables" => sub {
    plan tests => 2;

    @ARGV = (GET => '/env', 'foo=42', 'HTTP_X_REQUESTED_WITH=XMLHttpRequest');
    Test::Output::stdout_like
    (
    sub { $psgi = Dancer->start },
    qr{X-Powered-By: Perl Dancer.*XMLHttpRequest}sm, 
    "output looks good"
    );

    is $psgi->[0], 200, "psgi response is ok";
};
