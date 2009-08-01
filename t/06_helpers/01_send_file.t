use Test::More import => ['!pass'];

use lib 't';
use TestUtils;
use Dancer;

plan tests => 3;

ok(get('/cat/:file', sub {
    send_file(params->{file});
}), '/cat/:file route defined');

my $req = fake_request(GET => '/cat/file.txt');

Dancer::SharedData->cgi($req);
my $resp = Dancer::Renderer->get_action_response();

ok(defined($resp), "route handler found for /cat/file.txt");
is_deeply( [split(/\n/, $resp->{body})], [1,2,3], 'send_file worked as expected');
