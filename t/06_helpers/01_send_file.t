use Test::More import => ['!pass'];

use lib 't';
use TestUtils;
use Dancer;
use Dancer::FileUtils 'read_glob_content';

plan tests => 4;

ok(get('/cat/:file', sub {
    send_file(params->{file});
}), '/cat/:file route defined');

my $req = fake_request(GET => '/cat/file.txt');

Dancer::SharedData->cgi($req);
my $resp = Dancer::Renderer->get_action_response();

ok(defined($resp), "route handler found for /cat/file.txt");
is(ref($resp->{content}), 'GLOB', "content is a File handle");

my $content = read_glob_content($resp->{content});
is_deeply( [split(/\n/, $content)], [1,2,3], 'send_file worked as expected');
