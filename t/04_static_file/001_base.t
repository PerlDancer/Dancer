use strict;
use warnings;

use Test::More tests => 3, import => ['!pass'];
use Dancer::Test;

use Dancer ':syntax';

set public => path(dirname(__FILE__), 'static');
my $public = setting('public');

my $req = [ GET => '/hello.txt' ];
response_is_file $req;

my $resp = Dancer::Test::_get_file_response($req);
is_deeply($resp->headers_to_array, ['Content-Type' => 'text/plain'], "response header looks good for @$req");
is(ref($resp->{content}), 'GLOB', "response content looks good for @$req");
