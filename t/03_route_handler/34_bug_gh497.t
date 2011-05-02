use Dancer ':tests', ':syntax';
use Dancer::Test;

use Test::More;

plan tests => 2;

post '/foo.:format' => sub { params->{format} };
post '/bar/:id'     => sub { params->{id} };

response_content_is([POST => '/foo.json'], "json");
response_content_is([POST => '/bar/1'], "1");
