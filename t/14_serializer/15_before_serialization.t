use strict;
use warnings;

use Test::More import => ['!pass'];

plan skip_all => "JSON is needed to run this tests"
    unless Dancer::ModuleLoader->load('JSON');

use Dancer ':syntax';
use Dancer::Test;

set serializer => 'JSON';

plan tests => 5;

ok(
    before_serialization sub {
        my $response = shift;
        $response->content->{foo} = 'bar';
        $response->header('X-Serializer' => 'x-json');
    }
);

ok(
    get '/' => sub {
        {foo => 'baz'};
    }
);

route_exists [ GET => '/' ];
my $response = dancer_response(GET => '/');
my $content = from_json($response->content);
is_deeply($content, {foo => 'bar'});
is $response->header('X-Serializer'), 'x-json';
