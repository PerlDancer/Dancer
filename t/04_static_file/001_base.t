use strict;
use warnings;

use Test::More tests => 6, import => ['!pass'];

BEGIN {
    use_ok 'Dancer';
    use_ok 'Dancer::Config', 'setting';
}
use CGI;

set public => path(dirname(__FILE__), 'static');
my $public = setting('public');

ok((defined($public) && (-d $public)), 'public dir is set');

my $request = CGI->new;
$request->path_info('/hello.txt');
$request->request_method('GET');
my $path = $request->path_info;

Dancer::SharedData->cgi($request);
my $resp = Dancer::Renderer::get_file_response();
ok( defined($resp), "static file is found for $path");

is_deeply($resp->{head}, {content_type => 'text/plain'}, "response header looks good for $path");
is($resp->{body}, "hello there\n", "response content looks good for $path");
