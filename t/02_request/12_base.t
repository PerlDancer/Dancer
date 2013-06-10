use Test::More;
use Dancer::Request;

plan tests => 11;

my $env = {
    'psgi.url_scheme' => 'http',
    REQUEST_METHOD    => 'GET',
    SCRIPT_NAME       => '/foo',
    PATH_INFO         => '/bar/baz',
    REQUEST_URI       => '/foo/bar/baz',
    QUERY_STRING      => '',
    SERVER_NAME       => 'localhost',
    SERVER_PORT       => 5000,
    SERVER_PROTOCOL   => 'HTTP/1.1',
};

my $req = Dancer::Request->new(env => $env);
is $req->base, 'http://localhost:5000/foo';

is $req->uri_for('bar', { baz => 'baz' }),
    'http://localhost:5000/foo/bar?baz=baz';

is $req->uri_for('/bar'), 'http://localhost:5000/foo/bar';
ok $req->uri_for('/bar')->isa('URI'), 'uri_for returns a URI';
ok $req->uri_for('/bar', undef, 1)->isa('URI'), 'uri_for returns a URI (with $dont_escape)';

is $req->request_uri, '/foo/bar/baz';
is $req->path_info, '/bar/baz';

{
    local $env->{SCRIPT_NAME} = '';
    is $req->uri_for('/foo'), 'http://localhost:5000/foo';
}

{
    local $env->{SERVER_NAME} = 0;
    is $req->base, 'http://0:5000/foo';
    local $env->{HTTP_HOST} = 'oddhostname:5000';
    is $req->base, 'http://oddhostname:5000/foo';
}

subtest '$dont_escape' => sub {
    plan tests => 2;

    my $url = '/bar?a=1&b=2';

    is $req->uri_for($url) => 'http://localhost:5000/foo/bar%3Fa=1&b=2', 
        'escaped';

    is $req->uri_for( '/bar?a=1&b=2', {}, 1) 
        => 'http://localhost:5000/foo/bar?a=1&b=2', 
        'unescaped';
}
