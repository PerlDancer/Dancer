use strict;
use warnings;
use Test::More import => ['!pass'];
use Dancer::ModuleLoader;

plan skip_all => "Test::Output is needed for this test"
    unless Dancer::ModuleLoader->load("Test::Output");

plan tests => 3;

use Dancer;
use Dancer::Request;
use Dancer::SharedData;

set access_log => false;
set apphandler => 'Debug';
get '/' => sub { 42 };

my $req = Dancer::Request->new_for_request(get => '/');
my $psgi = Dancer->start($req);
is $psgi->[0], 200, "psgi response";

$req = Dancer::Request->new_for_request(get => '/');
$psgi = Dancer->dance($req);
is $psgi->[0], 200, "psgi response";

Dancer::SharedData->request($req);
$req = Dancer::Request->new_for_request(get => '/');
Test::Output::stdout_like(sub { Dancer->dance() }, 
    qr{X-Powered-By: Perl Dancer.*42}sm, 
    "start with no request given");
