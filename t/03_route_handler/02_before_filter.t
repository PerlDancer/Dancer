use strict;
use warnings;

use Test::More tests => 17, import => ['!pass'];
use Dancer ':syntax';
use Dancer::Test;

my $i = 0;

ok(
    before(
        sub {
            content_type('text/xhtml');
        }
    )
);

ok(
    before(
        sub {
            if ( request->path_info eq '/redirect_from' ) {
                redirect('/redirect_to');
            }
            else {
                params->{number} = 42;
                var notice => "I am here";
                request->path_info('/');
            }
        }
    ),
    'before filter is defined'
);

ok(
    get(
        '/' => sub {
            is( params->{number}, 42,             "params->{number} is set" );
            is( "I am here",      vars->{notice}, "vars->{notice} is set" );
            return 'index';
        }
    ),
    'index route is defined'
);

ok(
    get(
        '/redirect_from' => sub {
            $i++;
        }
    )
);

route_exists [GET => '/'];
response_exists [GET => '/'];

my $path = '/somewhere';
my $request = [ GET => $path ];

route_doesnt_exist $request, 
    "there is no route handler for $path...";

response_exists $request,
    "...but a response is returned though";

response_content_is $request, 'index', 
    "which is the result of a redirection to /";

response_headers_include [GET => '/redirect_from'] => [
    'Location' => '/redirect_to',
    'Content-Type' => 'text/xhtml',
];

is $i, 0, 'never gone to redirect_from';
