use Test::More tests => 6;

use strict;
use warnings FATAL => 'all';

use Dancer::Request;

%ENV = (
          'REQUEST_METHOD' => 'GET',
          'REQUEST_URI' => '/',
          'PATH_INFO' => '/',
          'QUERY_STRING' => 'foo=bar&number=42',
          );

my $req = Dancer::Request->new(env => \%ENV);
is $req->path, '/', 'path is /';
is $req->method, 'GET', 'method is get';
is_deeply scalar($req->params), {foo => 'bar', number => 42},
    'params are parsed';

$req = Dancer::Request->forward($req, { to_url => "/new/path"} );
is $req->path, '/new/path', 'path is changed';
is $req->method, 'GET', 'method is unchanged';
is_deeply scalar($req->params), {foo => 'bar', number => 42},
    'params are not touched';
