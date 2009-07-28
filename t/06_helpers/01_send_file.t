use Test::More import => ['!pass'];

use CGI;
use Dancer;

plan tests => 2;

ok(get('/cat/:file', sub {
    send_file(params->{file});
}), '/cat/:file route defined');

my $req = CGI->new;
$req->path_info('/cat/file.txt');
$req->request_method('GET');

Dancer::SharedData->cgi($req);
my $resp = Dancer::Renderer->get_action_response();

is_deeply( [split(/\n/, $resp->{body})], [1,2,3], 'send_file worked as expected');
