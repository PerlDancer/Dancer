use strict;
use warnings;

use Test::More import => ['!pass'];

plan skip_all => "JSON is needed to run this tests"
    unless Dancer::ModuleLoader->load('JSON');
plan tests => 5;

use Dancer ':syntax';
use Dancer::Test;

set serializer => 'JSON';
get '/' => sub{ { a => 1, b => 2, c => 3 }  };

for my $method (qw/GET HEAD/) {
    my $response = dancer_response($method => '/');
    is $response->status, 200, "status is 200 for $method";
    is $response->header('Content-Type'), 'application/json', "content_type is ok for $method";
}

my $response = dancer_response(HEAD => '/');
ok !$response->content;
