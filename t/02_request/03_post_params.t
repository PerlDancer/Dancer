use Test::More tests => 5;

use strict;
use warnings FATAL => 'all';
use Dancer::Request;

my $body = 'foo=bar&name=john&';
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
};

my $req = Dancer::Request->new($env);
is $req->path, '/', 'path is set';
is $req->method, 'POST', 'method is set';

is_deeply scalar($req->params), $expected_params, 'params are OK';
is $req->params->{'name'}, 'john', 'params accessor works';

my %params = $req->params;
is_deeply scalar($req->params), \%params, 'params wantarray works';

