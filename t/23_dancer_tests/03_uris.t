use strict;
use warnings;

use Test::More tests => 5;

use Dancer ':tests';
use Dancer::Test;

get '/uri_base' => sub { request->uri_base };
get '/uri' => sub { request->uri };
get '/path' => sub { request->path };

response_content_is '/uri_base' => 'http://localhost';
response_content_is '/uri' => '/uri';
response_content_is '/uri?with=params' => '/uri?with=params';
response_content_is '/path' => '/path';
response_content_is '/path?with=params' => '/path';

