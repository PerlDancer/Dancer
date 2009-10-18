use Test::More tests => 2, import => ['!pass'];

use Dancer;
use lib 't';
use TestUtils;

set show_errors => 1;

get '/error' => sub {
    send_error "FAIL";
};

my $res = get_response_for_request(GET => '/error');
is($res->{status}, 500, "status is 500 on send_error");
like $res->{content}, qr/FAIL/, "content of error is kept";
