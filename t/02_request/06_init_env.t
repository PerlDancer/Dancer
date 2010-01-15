use Test::More tests => 3;

use strict;
use warnings FATAL => 'all';

use Dancer::Request;

my $custom_env = { 
    QUERY_STRING   => 'foo=bar',
    PATH_INFO      => '/stuff',
    REQUEST_METHOD => 'GET',
};

my $req = Dancer::Request->new($custom_env);
is $req->path, '/stuff', 'path is set from custom env';
is $req->method, 'GET', 'method is set from custom env';
is_deeply scalar($req->params), {foo => 'bar'}, 'params are set from custom env';
