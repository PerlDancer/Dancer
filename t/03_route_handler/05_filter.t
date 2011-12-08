use Test::More import => ['!pass'];
use strict;
use warnings;
use Dancer;
use Dancer::Test;

plan tests => 19;

# simple before filter
{
    my $i = 0;

    hook before => sub { content_type('text/xhtml'); };
    hook before => sub {
        if ( request->path_info eq '/redirect_from' ) {
            redirect('/redirect_to');
        }
        elsif( request->path_info eq '/' or request->path eq '/somewhere' ){
            params->{number} = 42;
            var notice => "I am here";
            request->path_info('/');
        }
    };

    get '/' => sub {
        is( params->{number}, 42,             "params->{number} is set" );
        is( "I am here",      vars->{notice}, "vars->{notice} is set" );
        return 'index';
    };

    get '/redirect_from' => sub { $i++; };

    route_exists       [ GET => '/' ];
    response_status_is [ GET => '/' ] => 200;

    my $path = '/somewhere';
    my $request = [ GET => $path ];

    route_doesnt_exist $request => "there is no route handler for $path...";

    response_status_is  $request => 200,
      "...but a response is returned though";
    response_content_is $request => 'index',
      "which is the result of a redirection to /";

    response_headers_include [ GET => '/redirect_from' ] => [
        'Location'     => 'http://localhost/redirect_to',
        'Content-Type' => 'text/xhtml',
    ];

    is $i, 0, 'never gone to redirect_from';
}

# filters and params
{
    hook before => sub {
        return if request->path !~ /foo/;
        ok( defined( params->{'format'} ),
            "param format is defined in before filter" );
    };

    get '/foo.:format' => sub {
        ok( defined( params->{'format'} ),
            "param format is defined in route handler" );
        1;
    };
    route_exists        [ GET => '/foo.json' ];
    response_content_is [ GET => '/foo.json' ], 1;
}

# filter and halt
{
    hook before => sub {
        unless (params->{'requested'}) {
            return halt("stopped");
        }
    };

    hook before => sub {
        unless (params->{'requested'}) {
            halt("another halt");
        }
    };

    get '/halt' => sub {
        "route"
    };

    response_content_is [GET => '/halt'], "stopped";
    response_content_is [GET => '/halt', { params => {requested => 1} }], "route";
}

