use Test::More;
use Dancer::Request;

plan tests => 2;

my $env = {
    'psgi.url_scheme' => 'http',
    REQUEST_METHOD    => 'GET',
    SCRIPT_NAME       => '/',
    PATH_INFO         => '/bar/baz',
    REQUEST_URI       => '/foo/bar/baz',
    QUERY_STRING      => '',
    SERVER_NAME       => 'localhost',
    SERVER_PORT       => 5000,
    SERVER_PROTOCOL   => 'HTTP/1.1',
};

my $req = Dancer::Request->new(env => $env);
is(
    $req->uri_base,
    'http://localhost:5000',
    'remove trailing slash if only one',
);

$env->{'SCRIPT_NAME'} = '/foo/';
$req = Dancer::Request->new(env => $env);
is(
    $req->uri_base,
    'http://localhost:5000/foo/',
    'keeping trailing slash if not only',
);
