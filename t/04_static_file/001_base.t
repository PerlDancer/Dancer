use strict;
use warnings;

use lib 't';
use TestUtils;
use Test::More tests => 6, import => ['!pass'];

BEGIN {
    use_ok 'Dancer';
    use_ok 'Dancer::Config', 'setting';
}

set public => path(dirname(__FILE__), 'static');
my $public = setting('public');

ok((defined($public) && (-d $public)), 'public dir is set');

my $request = TestUtils::fake_request('GET' => '/hello.txt');
my $path = $request->path_info;

Dancer::SharedData->request($request);
my $resp = Dancer::Renderer::get_file_response();
ok( defined($resp), "static file is found for $path");

is_deeply($resp->{headers}, ['Content-Type' => 'text/plain'], "response header looks good for $path");
is(ref($resp->{content}), 'GLOB', "response content looks good for $path");
