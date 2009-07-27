use strict;
use warnings;

use Test::More tests => 9, import => ['!pass'];

sub build_request {
    my ($path) = @_;
    my $request = CGI->new;
    $request->path_info($path);
    $request->request_method('GET');
    return $request;
}

BEGIN {
    use_ok 'Dancer';
    use_ok 'Dancer::Config', 'setting';
}

set public => path(dirname(__FILE__), 'static');
my $public = setting('public');

my $path = '/hello.foo';
my $request = build_request($path);

Dancer::SharedData->cgi($request);
my $resp = Dancer::Renderer::get_file_response();
ok( defined($resp), "static file is found for $path");
is_deeply($resp->{head}, 
    {content_type => 'text/plain'}, 
    "$path is sent as text/plain");

ok(mime_type(foo => 'text/foo'), 'mime type foo is set as text/foo');

Dancer::SharedData->cgi($request);
$resp = Dancer::Renderer::get_file_response();
ok( defined($resp), "static file is found for $path");
is_deeply($resp->{head}, 
    {content_type => 'text/foo'}, 
    "$path is sent as text/foo");

$path = '/hello.txt';
$request = build_request($path);

Dancer::SharedData->cgi($request);
$resp = Dancer::Renderer::get_file_response();
ok( defined($resp), "static file is found for $path");
is_deeply($resp->{head}, 
    {content_type => 'text/plain'}, 
    "$path is sent as text/plain");
