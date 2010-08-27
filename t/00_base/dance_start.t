use strict;
use warnings;
use Test::More import => ['!pass'];

plan tests => 2;

use Dancer;
use Dancer::Request;
use Dancer::SharedData;

set apphandler => 'Debug';
get '/' => sub { 42 };

my $req = Dancer::Request->new_for_request(get => '/');
my $psgi = Dancer->start($req);
is $psgi->[0], 200, "psgi response";

my $req = Dancer::Request->new_for_request(get => '/');
my $psgi = Dancer->dance($req);
is $psgi->[0], 200, "psgi response";

