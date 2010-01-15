use Test::More import => ['!pass'];
use lib 't';
use TestUtils;

my @methods = qw(get head put post delete options);
plan tests => scalar(@methods) + 5;

use Dancer;

ok(get('/', sub { 'get' }), "GET / defined ");
ok(post('/', sub { 'post' }), "POST / defined ");
ok(put('/', sub { 'put' }), "PUT / defined ");
ok(del('/', sub { 'delete' }), "DELETE / defined ");
ok(options('/', sub { 'options' }), "OPTIONS / defined ");

foreach my $m (@methods) {
    my $request = TestUtils::fake_request($m => '/');
    Dancer::SharedData->request($request);
    my $response = Dancer::Renderer::get_action_response();
    ok(defined($response), "route handler found for method $m");
}
