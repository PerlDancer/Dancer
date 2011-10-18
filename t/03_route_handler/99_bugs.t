use Test::More import => ['!pass'];
use strict;
use warnings;
use Dancer;
use Dancer::Test;

plan tests => 19;

# issue gh_77
{

    get '/:page' => sub {
        my $page = params->{page};
        return pass() unless $page =~ m/about|help|intro|upload/;
        return $page;
    };

    get '/status' => sub { 'status' };
    get '/search' => sub { 'search' };

    response_content_is [GET => '/intro'], 'intro';   # this work
    response_content_is [GET => '/status'], 'status'; # this is a 404, shouldn't
    response_content_is [GET => '/status'], 'status'; # now this work
    response_content_is [GET => '/search'], 'search'; # we get status here instead
    response_content_is [GET => '/search'], 'search'; # now this works
}


# issue gh_190
{
    my $i = 0;

    hook before => sub { redirect '/somewhere' if request->path eq '/' };
    get( '/', sub { $i++; 'Hello' } );

    route_exists [ GET => '/' ];
    response_headers_include [ GET => '/' ] => [ Location => 'http://localhost/somewhere' ];
    response_content_is      [ GET => '/' ] => '';
    is $i, 0;
}

# issue gh_393
# Test that vars are reset between each request by Dancer::Test
{
    var foo => 0;

    get '/reset' => sub { vars->{foo} += 1; vars->{foo}; };

    for ( 1 .. 10 ) {
        response_content_is [ GET => '/reset' ] => 1, "foo is 1";
    }
}

