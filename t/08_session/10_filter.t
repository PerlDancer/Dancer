use strict;
use warnings;

use Test::More import => ['!pass'], tests => 2;
use Dancer ':syntax';
use Dancer::Test;

hook before => sub {
    my $data = session;
    #warn "on a $data";
    #redirect '/nonexistent'
    #unless session || request->path =~ m{/login}sxm;
};

get '/login' => sub {
    '/login';
};

route_exists       [ GET => '/login' ];
response_status_is [ GET => '/login' ] => 200,
