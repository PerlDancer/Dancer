use strict;
use warnings;

use Test::More import => ['!pass'];

use Dancer::Test;

use Dancer ':syntax';

plan tests => 5;

my $pass = 0;

hook before => sub {
    redirect '/'
      unless request->path eq '/'
          || request->path eq '';
};

get '/' => sub { return "im home"; };
get '/false' => sub { $pass++; return "im false"; };

response_status_is  [ GET => '/' ] => 200;
response_content_is [ GET => '/' ] => "im home";

response_status_is       [ GET => '/false' ] => 302;
response_headers_include [ GET => '/false' ] => ['Location'=>'http://localhost/'];

is $pass, 0;
