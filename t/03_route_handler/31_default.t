# this test makes sure the auto_page feature works as expected
# whenever a template matches a requested path, a default route handler 
# takes care of rendering it.
use strict;
use warnings;
use Test::More import => ['!pass'], tests => 12;
use File::Spec;
use lib File::Spec->catdir( 't', 'lib' );

use Dancer::Test;

{
    package Foo;
    use Dancer;

    set views => path(dirname(__FILE__), 'views');

    get '/' => sub { "here comes /\n" };
    get '/simple' => sub { "here comes /simple\n" };
    get '/path/to' => sub { "here comes /path/to\n" };
    default sub { return scalar reverse request->path() };
}

my $resp = dancer_response('GET' => '/hello');
ok( defined($resp), "response found for /hello");
is $resp->{status}, 200, "response is 200";
is $resp->{content}, "olleh/", "content looks good";

for my $path ( qw( / /simple /path/to ) ) {
   my $resp = dancer_response(GET => $path);
   ok( defined($resp), "response found for explicit route $path");
   is $resp->{status}, 200, "response is 200";
   is $resp->{content}, "here comes $path\n", "content looks good";
}

