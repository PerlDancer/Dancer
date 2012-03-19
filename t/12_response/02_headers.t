#
# I really suck ass at tests, pardon my French :) - damog
#

use Dancer ':tests';

use Test::More;
use Dancer::Test;

get '/header', sub {
    header 'X-Foo' => 'xfoo';
};

get '/headers', sub {
    headers 'X-A' => 'a', 'X-B' => 'b';
};

get '/headers/more', sub {
    headers 'X-Foo' => 'bar';
    header 'X-Bar' => 'schmuk', 'X-XXX' => 'porn';
    header 'Content-Type', 'text/css'; # this gets overriden 
};

get '/headers/content_type', sub {
    content_type 'text/xml';
    headers 'Content-Type' => 'text/css';
};

get '/headers/multiple' => sub {
    headers 'foo' => 1, 'foo' => 2, 'bar' => 3, 'foo' => 4;
};

plan tests => 11;

# /header
my $res = dancer_response(GET => '/header');
is($res->header('X-Foo'), 
	'xfoo', 
	"X-Foo looks good for /header");

# /headers
$res = dancer_response(GET => '/headers');
is($res->header('X-A'),
	'a', 
	"X-A looks good for /headers");
is($res->header('X-B'), 'b', 'X-B looks good for /headers');

# /headers/more
$res = dancer_response(GET => '/headers/more');
is($res->header('X-Foo'), 'bar', "X-Foo looks good for /headers/more");
is($res->header('X-Bar'), 'schmuk', "X-Bar looks good for /headers/more");
is($res->header('X-XXX'), 'porn', "X-XXX looks good for /headers/more");
is($res->header('Content-Type'), 'text/css', "Content-Type looks good for /headers/more");

# /headers/content_type
$res = dancer_response(GET => '/headers/content_type');
is($res->header('Content-Type'), 'text/css', "Content-Type looks good for /headers/content_type");

# /headers/multiple
response_headers_include
  [ GET => '/headers/multiple'] =>
  [
   'Content-Type' => 'text/html',
   Bar => 3,
   Foo => 1,
   Foo => 2,
   Foo => 4,
  ], 'multiple headers are kept';

my $response = dancer_response(GET => '/headers/multiple');
response_headers_include
  $response =>
  [
   'Content-Type' => 'text/html',
   Bar => 3,
   Foo => 1,
   Foo => 2,
   Foo => 4,
  ], '... even if we pass a response object to response_headers_include()';

# Dancer::Response header's API
$res = Dancer::Response->new(
    status  => 200,
    headers => [ 'Content-type', 'application/json' ],
    content => "ok"
);

my $ct = $res->header('CONTENT-TYPE');
is $ct, 'application/json';
