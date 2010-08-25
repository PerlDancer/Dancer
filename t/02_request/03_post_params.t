use Test::More tests => 7;

use strict;
use warnings FATAL => 'all';
use Dancer::Request;

my $body = 'foo=bar&name=john&hash=2&hash=4&hash=6&';
open my $in, '<', \$body;

my $env = {
        CONTENT_LENGTH => length($body),
        CONTENT_TYPE   => 'application/x-www-form-urlencoded',
        REQUEST_METHOD => 'POST',
        SCRIPT_NAME    => '/',
        'psgi.input'   => $in,
};

my $expected_params = {
    name => 'john',
    foo  => 'bar',
    hash => [2, 4, 6],
};

my $req = Dancer::Request->new($env);
is $req->path, '/', 'path is set';
is $req->method, 'POST', 'method is set';
ok $req->is_post, 'method is post';
my $request_to_string = $req->to_string;
is $request_to_string, '[#1] POST /';

is_deeply scalar($req->params), $expected_params, 'params are OK';
is $req->params->{'name'}, 'john', 'params accessor works';

my %params = $req->params;
is_deeply scalar($req->params), \%params, 'params wantarray works';

