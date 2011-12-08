use Test::More tests => 2, import => ['!pass'];

use Dancer ':syntax';
use Dancer::Test;

set show_errors => 1;

get '/error' => sub {
    send_error "FAIL";
    # The next line is not executed, as 'send_error' breaks the route workflow
    die;
};

response_status_is [GET => '/error'] => 500,
  "status is 500 on send_error";
response_content_like [GET => '/error'] => qr/FAIL/, "content of error is kept";
