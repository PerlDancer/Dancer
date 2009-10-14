use strict;
use warnings;
use Test::More import => ['!pass'];
use Dancer;
use Dancer::ModuleLoader;

use lib 't';
use TestUtils;

set show_errors => 1;

plan skip_all => "CGI::Session is needed" 
    unless Dancer::ModuleLoader->load('CGI::Session');

plan tests => 1;

ok(set(session => 1), "session => 1");

#  TODO 
# this before filter must be automatically set
# when enabling the session engline
# TODO should also look for a cookie first instead of params
before sub { Dancer::Session->init(params->{'session_id'}) };

get '/set' => sub { session user_id => 42 };
get '/get' => sub { session->{'user_id'} };

# /set user_id => 42
my $path = '/set';
my $cgi = fake_request(GET => $path);
Dancer::SharedData->cgi($cgi);
my $response = Dancer::Renderer::get_action_response();

is($response->{content}, 1, "session key/value pair set");

