use Test::More tests => 5, import => ['!pass'];
use strict;
use warnings;

use Dancer::Test;

{
    use Dancer;

#    set logger => 'console';
#    set 'log' => 'core';

    get '/:page' => sub {
        my $page = params->{page};
        return pass() unless $page ~~ [qw/about help intro upload/];
        return $page;
    };
    get '/status' => sub { 'status' };
    get '/search' => sub { 'search' };
}

response_content_is [GET => '/intro'], 'intro';   # this work
response_content_is [GET => '/status'], 'status'; # this is a 404, shouldn't
response_content_is [GET => '/status'], 'status'; # now this work
response_content_is [GET => '/search'], 'search'; # we get status here instead
response_content_is [GET => '/search'], 'search'; # now this works
