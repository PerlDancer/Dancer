use strict;
use warnings;

use Test::More import => ['!pass'];

use Dancer::Test;

use Dancer ':syntax';

my $pass = 0;

before sub {
    redirect '/'
      unless request->path eq '/'
          || request->path eq '';
};

get '/' => sub { return "im home"; };
get '/false' => sub { $pass++; return "im false"; };

response_exists [ GET => '/' ];
response_content_is [ GET => '/' ], "im home";

response_exists [ GET => '/false' ];
response_headers_are_deeply [GET => '/false'], ['Location'=>'http://localhost/'];

is $pass, 0;

done_testing;
