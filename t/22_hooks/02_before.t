use strict;
use warnings;
use Test::More import => ['!pass'];

use Dancer ':syntax';
use Dancer::Test;

plan tests => 15;

my $i = 0;

ok(
   hook (before =>
        sub {
            content_type('text/xhtml');
        }
    )
);

ok(
   hook(before=>
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

get(
    '/' => sub {
        is( params->{number}, 42,             "params->{number} is set" );
        is( "I am here",      vars->{notice}, "vars->{notice} is set" );
        return 'index';
    }
);

get(
    '/redirect_from' => sub {
        $i++;
    }
);

route_exists       [ GET => '/' ];
response_status_is [ GET => '/' ] => 200;

my $path = '/somewhere';
my $request = [ GET => $path ];

route_doesnt_exist $request, "there is no route handler for $path...";

response_status_is $request => 200, "...but a response is returned though";

response_content_is $request, 'index',
  "which is the result of a redirection to /";

response_headers_are_deeply [ GET => '/redirect_from' ],
  [
    'Location'     => 'http://localhost/redirect_to',
    'Content-Type' => 'text/xhtml',
    'Server'       => "Perl Dancer ${Dancer::VERSION}",
    'X-Powered-By' => "Perl Dancer ${Dancer::VERSION}",
  ];

is $i, 0, 'never gone to redirect_from';

