use Test::More tests => 5;
use strict;
use warnings FATAL => 'all';
use Dancer::Request;

my $body = 'x=1&meth=post';
open my $in, '<', \$body;

my $env = {
        CONTENT_LENGTH => length($body),
        CONTENT_TYPE   => 'application/x-www-form-urlencoded',
        QUERY_STRING   => 'y=2&meth=get',
        REQUEST_METHOD => 'POST',
        SCRIPT_NAME    => '/',
        'psgi.input'   => $in,
};

my $mixed_params = {
    meth => 'post',
    x => 1,
    y => 2,
};

my $get_params = {
    y => 2,
    meth => 'get',
};

my $post_params = {
    x => 1,
    meth => 'post',
};

my $req = Dancer::Request->new($env);
is $req->path, '/', 'path is set';
is $req->method, 'POST', 'method is set';

is_deeply scalar($req->params), $mixed_params, 'params are OK';
is_deeply scalar($req->params('body')), $post_params, 'body params are OK';
is_deeply scalar($req->params('query')), $get_params, 'query params are OK';

