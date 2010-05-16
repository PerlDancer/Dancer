use Test::More import => ['!pass'];
use t::lib::TestUtils;

use Dancer::Test;

my @methods = qw(get head put post delete options);
plan tests => 23;

use Dancer ':syntax';

ok(get('/', sub { 'get' }), "GET / defined ");
ok(post('/', sub { 'post' }), "POST / defined ");
ok(put('/', sub { 'put' }), "PUT / defined ");
ok(del('/', sub { 'delete' }), "DELETE / defined ");
ok(options('/', sub { 'options' }), "OPTIONS / defined ");

foreach my $m (@methods) {
    route_exists [$m => '/'], "route handler found for method $m";
    response_status_is [$m => '/'], 200, "response status is 200 for $m";

    my $content = $m;
    $content = '' if $m eq 'head';
    response_content_like [$m => '/'], qr/$content/, "response content is OK for $m";
}
