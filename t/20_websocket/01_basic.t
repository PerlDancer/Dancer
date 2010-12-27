use Test::More import => ['!pass'];
use Dancer ':syntax';

foreach my $req (qw(AnyMQ Plack Web::Hippie)) {
    plan skip_all =>  "$req is required to run websocket tests"
        unless Dancer::ModuleLoader->load($req);
}
plan tests => 2;

use Dancer::Plugin::WebSocket;
my $topic = Dancer::Plugin::WebSocket::_topic();
my $listener = AnyMQ->new_listener($topic);

websocket_send 'allo';

$listener->poll_once(sub {
    my @msgs = @_;
    is @msgs => 1, "got one websocket message";
    is_deeply $msgs[0] => { msg => 'allo' }, "got the right websocket message";
});
