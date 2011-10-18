use Test::More import => ['!pass'];
use strict;
use warnings;

plan tests => 2;

use Dancer ':syntax';
use Dancer::Test;

set show_errors => true;

{
    hook before => sub {
        FooBar->send_error; # FAIL
    };

    get '/' => sub {
        "route"
    };
}

response_status_is    [GET => '/'] => 500;
response_content_like [GET => '/'] => qr/FooBar-&gt;send_error/;
