use strict;
use warnings;
use Test::More import => ['!pass'];
use Dancer::ModuleLoader;

plan skip_all => "Test::Output is needed for this test"
    unless Dancer::ModuleLoader->load("Test::Output");

plan tests => 3;

use Dancer;

set startup_info => false, apphandler   => 'Debug';

get '/' => sub { 42 };

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
