
use Test::More tests => 2;
use strict;
use warnings;

use Dancer::Response;
use Dancer::Handler::Standalone;

my $r =
  Dancer::Response->new(
    headers => [ 'Location' => "http://good.com\nLocation: http://evil.com" ],
  );

my $res = Dancer::Handler::Standalone->render_response($r);
is_deeply(
    $res->[1],
    [ 'Location' => "http://good.com\r\n Location: http://evil.com", 'Content-Length' => 0,],
"CRLF injections are not allowed... a space is added to make the second line an RFC-compliant continuation line."
);

$r = Dancer::Response->new(
    headers => [
        'Content-Length' => 0,
        a                => "foo\nevil body",
    ]
);

$res = Dancer::Handler::Standalone->render_response($r);
is $res->[1]->[3], "foo\r\n evil body";
