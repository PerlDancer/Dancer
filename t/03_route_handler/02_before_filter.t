use strict;
use warnings;

use Test::More 'no_plan', import => ['!pass'];
use Dancer ':syntax';
use Dancer::Test;

ok(before(sub { 
    params->{number} = 42;
    var notice => "I am here";
    request->path_info('/');
}), 'before filter is defined');

ok(get('/' => sub {
    is(params->{number}, 42, "params->{number} is set");
    is("I am here", vars->{notice}, "vars->{notice} is set");
    return 'index';
}), 'index route is defined');

my $path = '/somewhere';
my $request = [ GET => $path ];

route_doesnt_exist $request, 
    "there is no route handler for $path...";

response_exists $request,
    "...but a response is returned though";

response_content_is $request, 'index', 
    "which is the result of a redirection to /";
