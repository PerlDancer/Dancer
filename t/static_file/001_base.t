use strict;
use warnings;

use Test::More tests => 5, import => ['!pass'];

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

my $resp = Dancer::Renderer::get_file_response($request);
ok( defined($resp), "static file is found for $path");

is($resp->{body}, "hello there\n", 'static file content looks good');
