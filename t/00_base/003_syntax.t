use Test::More import => ['!pass'];

my @keywords = qw(
    after
    any
    before
    before_template
    cookies
    config
    content_type
    dance
    debug
    del
    dirname
    error
    false
    from_dumper
    from_json
    from_yaml
    from_xml
    get
    halt
    header
    headers
    layout
    load
    load_app
    load_plugin
    logger
    mime_type
    options
    params
    pass
    path
    post
    prefix
    put
    r
    redirect
    request
    send_file
    send_error
    set
    setting
    set_cookie
    session
    splat
    status
    start
    template
    to_dumper
    to_json
    to_yaml
    to_xml
    true
    upload
    captures
    uri_for
    var
    vars
    warning
); 

plan tests => scalar(@keywords);

use Dancer ':syntax';

foreach my $symbol (@keywords) {
    ok(exists($::{$symbol}), "symbol `$symbol' is exported");
}
