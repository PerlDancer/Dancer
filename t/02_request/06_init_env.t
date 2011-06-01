use Test::More;

use strict;
use warnings FATAL => 'all';

use Dancer::Request;

my $custom_env = {
    'SERVER_PORT'    => 3000,
    SERVER_PROTOCOL  => 'http',
    'QUERY_STRING'   => 'foo=bar',
    'PATH_INFO'      => '/stuff',
    'REQUEST_METHOD' => 'GET',
    'XAUTHORITY' => '/var/run/gdm/auth-for-sukria-6en6nX/database',
    'HTTP_ACCEPT' => 'image/png,image/*;q=0.8,*/*;q=0.5; text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
    'HTTP_USER_AGENT' => 'Mozilla/5.0 (X11; U; Linux x86_64; fr; rv:1.9.1.5) Gecko/20091109 Ubuntu/9.10 (karmic) Firefox/3.5.5; Mozilla/5.0 (X11; U; Linux x86_64; fr; rv:1.9.1.5) Gecko/20091109 Ubuntu/9.10 (karmic) Firefox/3.5.5',
    'HTTP_ACCEPT_LANGUAGE' => 'fr,fr-fr;q=0.8,en-us;q=0.5,en;q=0.3; fr,fr-fr;q=0.8,en-us;q=0.5,en;q=0.3',
    'HTTP_ACCEPT_CHARSET' => 'ISO-8859-1,utf-8;q=0.7,*;q=0.7; ISO-8859-1,utf-8;q=0.7,*;q=0.7',
    'HTTP_HOST' => 'localhost:3000; localhost:3000',
    'HTTP_KEEP_ALIVE' => '300; 300',
    'HTTP_ACCEPT_ENCODING' => 'gzip,deflate; gzip,deflate',
    'HTTP_CONNECTION' => 'keep-alive; keep-alive',
};
my @http_env = grep /^HTTP_/, keys (%$custom_env);
plan tests => 6 + (2 * scalar(@http_env));

my $req = Dancer::Request->new(env => $custom_env);
is $req->path, '/stuff', 'path is set from custom env';
is $req->method, 'GET', 'method is set from custom env';
is_deeply scalar($req->params), {foo => 'bar'}, 'params are set from custom env';

is $req->port, 3000, 'port is ok';
is $req->protocol, 'http', 'protocol is ok';
ok !$req->secure, 'not https';

foreach my $http (@http_env) {
    my $key = lc $http;
    $key =~ s/^http_//;
    is $req->{$key}, $custom_env->{$http}, "$http is found in request ($key)";
    is $req->$key, $custom_env->{$http}, "$key is an accessor";
}

