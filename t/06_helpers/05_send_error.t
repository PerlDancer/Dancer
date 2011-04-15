use Test::More tests => 2, import => ['!pass'];

use Dancer ':syntax';
#use File::Spec;
#use lib File::Spec->catdir( 't', 'lib' );
#use TestUtils;
use Dancer::Test;

set show_errors => 1;

get '/error' => sub {
    send_error "FAIL";
};

response_status_is [GET => '/error'] => 500,
  "status is 500 on send_error";
response_content_like [GET => '/error'] => qr/FAIL/, "content of error is kept";
