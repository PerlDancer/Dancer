use Test::More import => ['!pass'];

my @keywords = qw(
    before
    content_type
    dirname
    false
    get 
    layout
    mime_type
    params
    pass
    path
    post 
    r
    request
    send_file
    set
    splat
    status
    template
    true
    var
    vars
); 

plan tests => scalar(@keywords);

use Dancer;

foreach my $symbol (@keywords) {
    ok(exists($::{$symbol}), "symbol `$symbol' is exported");
}
