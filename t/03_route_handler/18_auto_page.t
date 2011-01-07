# this test makes sure the auto_page feature works as expected
# whenever a template matches a requested path, a default route handler 
# takes care of rendering it.
use strict;
use warnings;
use Test::More import => ['!pass'], tests => 14;
use File::Spec;
use lib File::Spec->catdir( 't', 'lib' );

use Dancer::Test;

{
    package Foo;
    use Dancer;

    set views => path(dirname(__FILE__), 'views');
    set auto_page => true;
#    set logger => 'console';
#    set 'log' => 'core';

    get '/' => sub { "here comes /\n" };
    get '/simple' => sub { "here comes /simple\n" };
    get '/path/to' => sub { "here comes /path/to\n" };
}

my $resp = dancer_response('GET' => '/hello');
ok( defined($resp), "response found for /hello");
is $resp->{status}, 200, "response is 200";
is $resp->{content}, "Hello\n", "content looks good";

$resp = dancer_response('GET' => '/falsepage');
ok( defined($resp), "response found for non existent page");

is $resp->{status}, 404, "response is 404";

for my $path ( qw( / /simple /path/to ) ) {
   my $resp = dancer_response(GET => $path);
   ok( defined($resp), "response found for explicit route $path");
   is $resp->{status}, 200, "response is 200";
   is $resp->{content}, "here comes $path\n", "content looks good";
}
