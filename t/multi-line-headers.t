
use Test::More 'no_plan';
use strict;
use warnings;

use Dancer::Response;
use Dancer::Handler::Standalone;

my $r = Dancer::Response->new(
   headers      => [ 'Location' => "http://good.com\nLocation: http://evil.com" ], 
);

{
    my $out;
    close STDOUT;
    open STDOUT, '>', \$out or die "Can't open STDOUT: $!";
    Dancer::Handler::Standalone->render_response($r),

is( 
    $out,
"HTTP/1.0 200 OK\r\nLocation: http://good.com\r\n Location: http://evil.com\r\n\r\n" ,
"CRLF injections are not allowed... a space is added to make the second line an RFC-compliant continuation line."); 
}

