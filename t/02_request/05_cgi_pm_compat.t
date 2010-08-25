use Test::More tests => 5;

use strict;
use warnings FATAL => 'all';

use Dancer::Request;

my $req = Dancer::Request->new_for_request(get => '/stuff');
is $req->path, '/stuff', "path is set";
is $req->method, 'GET', "method is set";

is $req->path_info, '/stuff', 'path_info alias reads';
$req->path_info('/other');
is $req->path_info, '/other', 'path_info alias writes';

is $req->request_method, 'GET', 'method is set';
