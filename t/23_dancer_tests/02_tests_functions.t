use strict;
use warnings;

use Test::More;

plan tests => 35;

use Dancer qw/ :syntax :tests /;
use Dancer::Test;

# verify that all test helper functions are behaving the way
# we want

our $route = '/marco';

get $route => sub { 'polo' };

my $users = {};
my $last_id = 0;

get '/user/:id' => sub {
    my $id = params->{'id'};
    { user => $users->{$id} };
};

post '/user' => sub {
    my $id   = ++$last_id;
    my $user = params('body');
    $user->{id} = $id;
    $users->{$id} = $user;

    { user => $users->{$id} };
};

del '/user/:id' => sub {
    my $id      = params->{'id'};
    my $deleted = $users->{$id};
    delete $users->{$id};
    { user => $deleted };
};

get '/query' => sub {
    return join(":",params('query'));
};

post '/upload' => sub {
	return upload('payload')->content;
};

any '/headers' => sub {
    return request->headers;
};

my $resp = dancer_response GET => '/marco';

my @req = ( [ GET => $route ], $route, $resp );

test_helping_functions( $_ ) for @req;

response_status_is [ GET => '/satisfaction' ], 404, 'response_doesnt_exist';
response_status_isnt [ GET => '/marco' ], 404, 'response_exists';

sub test_helping_functions {
    my $req = shift;

    response_status_is $req => 200;
    response_status_isnt $req => 613;

    response_content_is $req => 'polo';
    response_content_isnt $req => 'stuff';
    response_content_is_deeply $req => 'polo';
    response_content_like $req => qr/.ol/;
    response_content_unlike $req => qr/\d/;
}

## POST
my $r = dancer_response( POST => '/user', { body => { name => 'Alexis' } } );
is_deeply $r->{content}, { user => { id => 1, name => "Alexis" } },
  "create user works";

$r = dancer_response( GET => '/user/1' );
is_deeply $r->{content}, { user => { id => 1, name => 'Alexis' } },
  "user 1 is defined";

$r = dancer_response( DELETE => '/user/1' );
is_deeply $r->{content},
  { user => { id => 1, name => 'Alexis', } },
  "user 1 is deleted";

$r = dancer_response(
    POST => '/user',
    { body => { name => 'Franck Cuny' } }
);
is_deeply $r->{content}, { user => { id => 2, name => "Franck Cuny" } },
  "id is correctly increased";

$r = dancer_response( GET => '/query', { params => {foo => 'bar'}});
is $r->{content}, "foo:bar", 'passed fake query params';

$r = dancer_response( GET => '/query?foo=bar' );
is $r->{content}, "foo:bar", 'passed params in query';

my $data = "She sells sea shells by the sea shore";
$r = dancer_response(
	POST => '/upload', 
	{ files => [{name => 'payload', filename =>'test.txt', data => $data }] }
);
is $r->{content}, $data, "file data uploaded";

$r = dancer_response(GET => '/headers');
isa_ok $r->content, 'HTTP::Headers', 'The request headers';

$r = dancer_response(POST => '/headers', { headers => [ 'Content_Type' => "text/plain" ] });
isa_ok $r->content, 'HTTP::Headers', 'The request headers';
is $r->content->header('Content-Type'), "text/plain", "Content-Type preserved";

$r = dancer_response(POST => '/headers', { headers => HTTP::Headers->new('Content-Type' => "text/plain" ) });
isa_ok $r->{content}, 'HTTP::Headers', 'The request headers';
is $r->content->header('Content-Type'), "text/plain", "Content-Type preserved";
