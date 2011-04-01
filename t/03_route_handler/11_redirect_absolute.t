use strict;
use warnings;

use Test::More import => ['!pass'];
use Dancer::Test;

use Dancer ':syntax';

plan tests => 3;

get '/absolute_with_host' => sub { redirect "http://foo.com/somewhere"; };
get '/absolute' => sub { redirect "/absolute"; };
get '/relative' => sub { redirect "somewhere/else"; };

my $res = dancer_response GET => '/absolute_with_host';
is $res->header('Location') => 'http://foo.com/somewhere';

$res = dancer_response GET => '/absolute';
is $res->header('Location') => '/absolute';

$res = dancer_response GET => '/relative';
is $res->header('Location') => 'http://localhost/somewhere/else';
