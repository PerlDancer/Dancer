use strict;
use warnings;

use Test::More 'no_plan', import => ['!pass'];
use Dancer;

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
my $cgi = CGI->new;
$cgi->request_method('GET');
$cgi->path_info($path);

Dancer::SharedData->cgi($cgi);
my $response = Dancer::Renderer::get_action_response();
ok(defined($response), "route handler found for $path");
is($response->{body}, 'index', "$path got redirected to /");
