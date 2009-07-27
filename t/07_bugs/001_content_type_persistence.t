# bug: 
# the default content-type (text/html) is sent after the 
# first request, event if content_type is changed.

use Test::More tests => 2, import => ['!pass'];

{
    use Dancer;
    content_type 'text/plain';

    get '/' => sub { 1 };
}

use CGI;
use Dancer::SharedData;
my $req = CGI->new;
$req->path_info('/');
$req->request_method('GET');

my $resp;

Dancer::SharedData->cgi($req);
$resp = Dancer::Renderer->get_action_response();
is($resp->{head}{content_type}, 'text/plain', 'first request is text/plain');

Dancer::SharedData->cgi($req);
$resp = Dancer::Renderer->get_action_response();
is($resp->{head}{content_type}, 'text/plain', 'second request is text/plain');

