use Test::More import => ['!pass'];

my @keywords = qw(
    before
    cookies
    content_type
    dance
    debug
    dirname
    error
    false
    get 
    layout
    load
    logger
    mime_type
    params
    pass
    path
    post 
    put
    r
    redirect
    request
    send_file
    send_error
    set
    set_cookie
    session
    splat
    status
    template
    true
    var
    vars
    warning
); 

plan tests => scalar(@keywords);

use Dancer;

foreach my $symbol (@keywords) {
    ok(exists($::{$symbol}), "symbol `$symbol' is exported");
}
