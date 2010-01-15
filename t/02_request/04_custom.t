use Test::More tests => 7;

use strict;
use warnings FATAL => 'all';

use Dancer::Request;

%ENV = (
          'HTTP_ACCEPT' => 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
          'REQUEST_METHOD' => 'POST',
          'HTTP_USER_AGENT' => 'Mozilla/5.0 (X11; U; Linux x86_64; fr; rv:1.9.1.5) Gecko/20091109 Ubuntu/9.10 (karmic) Firefox/3.5.5',
          'HTTP_ACCEPT_LANGUAGE' => 'fr,fr-fr;q=0.8,en-us;q=0.5,en;q=0.3',
          'CONTENT_TYPE' => 'application/x-www-form-urlencoded',
          'HTTP_REFERER' => 'http://localhost:3000/',
          'CONTENT_LENGTH' => '33',
          'HTTP_ACCEPT_CHARSET' => 'ISO-8859-1,utf-8;q=0.7,*;q=0.7',
          'SERVER_PORT' => '3000',
          'SERVER_PROTOCOL' => 'HTTP/1.1',
          'REQUEST_URI' => '/',
          'HTTP_HOST' => 'localhost:3000',
          'PATH_INFO' => '/',
          'SERVER_SOFTWARE' => 'HTTP::Server::Simple/0.38',
          'QUERY_STRING' => 'foo=bar&number=42',
          'SERVER_URL' => 'http://localhost:3000/',
          );

my $req = Dancer::Request->new;
is $req->path, '/', 'path is /';
is $req->method, 'POST', 'method is post';
is_deeply scalar($req->params), {foo => 'bar', number => 42}, 
    'params are parsed';

$req = Dancer::Request->new_for_request('GET', '/stuff');
is $req->path, '/stuff', 'path is changed';
is $req->method, 'GET', 'method is changed';
is_deeply scalar($req->params), {foo => 'bar', number => 42}, 
    'params are not touched';

$req = Dancer::Request->new_for_request('GET', '/stuff', {user => 'sukria'});
is_deeply scalar($req->params), {foo => 'bar', number => 42, user => 'sukria'}, 
    'params are updated';

