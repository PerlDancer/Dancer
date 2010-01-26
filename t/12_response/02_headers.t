#
# I really suck ass at tests, pardon my French :) - damog
#

use Test::More import => ['!pass'];
use lib 't';
use TestUtils;

use Dancer;

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

plan tests => 9;

# /header
my $req = fake_request(GET => '/header');
Dancer::SharedData->request($req);
my $res = Dancer::Renderer::get_action_response();
my %headers = @{$res->{headers}};
is($headers{'X-Foo'}, 
	'xfoo', 
	"X-Foo looks good for /header");

# /headers
$req = fake_request(GET => '/headers');
Dancer::SharedData->request($req);
$res = Dancer::Renderer::get_action_response();
%headers = @{$res->{headers}};
is($headers{'X-A'}, 
	'a', 
	"X-A looks good for /headers");
is($headers{'X-B'}, 'b', 'X-B looks good for /headers');

# /headers/more
$req = fake_request(GET => '/headers/more');
Dancer::SharedData->request($req);
$res = Dancer::Renderer::get_action_response();
%headers = @{$res->{headers}};
is($headers{'X-Foo'}, 'bar', "X-Foo looks good for /headers/more");
is($headers{'X-Bar'}, 'schmuk', "X-Bar looks good for /headers/more");
is($headers{'X-XXX'}, 'porn', "X-XXX looks good for /headers/more");
is($headers{'Content-Type'}, 'text/html', "Content-Type looks good for /headers/more");

# /headers/content_type
$req = fake_request(GET => '/headers/content_type');
Dancer::SharedData->request($req);
$res = Dancer::Renderer::get_action_response();
%headers = @{$res->{headers}};
is($headers{'Content-Type'}, 'text/xml', "Content-Type looks good for /headers/content_type");


# /headers/multiple
$req = fake_request(GET => '/headers/multiple');
Dancer::SharedData->request($req);
$res = Dancer::Renderer::get_action_response();
is_deeply $res->{headers}, [
    foo => 1, 
    foo => 2, 
    bar => 3, 
    foo => 4,
    'Content-Type' => 'text/html'
], 'multiple headers are kept';

