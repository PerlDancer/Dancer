use Test::More;
use Dancer::Request;

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

my $req = Dancer::Request->new($env);
is $req->base, 'http://localhost:5000/foo';

is $req->uri_for('bar', { baz => 'baz' }),
    'http://localhost:5000/foo/bar?baz=baz';

is $req->uri_for('/bar'), 'http://localhost:5000/foo/bar';

is $req->path, '/foo/bar/baz';
is $req->path_info, '/bar/baz';

done_testing;
