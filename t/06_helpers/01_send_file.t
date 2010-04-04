use Test::More import => ['!pass'];
use t::lib::TestUtils;
use Dancer ':syntax';
use Dancer::FileUtils 'read_glob_content';

set public => path(dirname(__FILE__), 'public');

plan tests => 5;

ok(get('/cat/:file', sub {
    send_file(params->{file});
}), '/cat/:file route defined');

my $req = fake_request(GET => '/cat/file.txt');

Dancer::SharedData->request($req);
my $resp = Dancer::Renderer->get_action_response();


ok(defined($resp), "route handler found for /cat/file.txt");
my %headers = @{$resp->{headers}};
is($headers{'Content-Type'}, 'text/plain', 'mime_type is kept');
is(ref($resp->{content}), 'GLOB', "content is a File handle");

my $content = read_glob_content($resp->{content});
is_deeply( [split(/\n/, $content)], [1,2,3], 'send_file worked as expected');
