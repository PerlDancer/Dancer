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

    after_routes sub {
        get '/simple/:page' => sub { return 'default' };
    };
    get '/' => sub { "here comes /\n" };
    get '/simple/:page' => sub { return pass() if params->{page} eq 'whatever'; return "here comes /simple/hello\n" };
    get '/path/to' => sub { "here comes /path/to\n" };
}

my $resp = dancer_response('GET' => '/simple/whatever');
ok( defined($resp), "response found for /simple/whatever");
is $resp->{status}, 200, "response is 200";
is $resp->{content}, "default", "content looks good from low-priority route";

for my $path ( qw( / /simple/hello /path/to ) ) {
   my $resp = dancer_response(GET => $path);
   ok( defined($resp), "response found for explicit route $path");
   is $resp->{status}, 200, "response is 200";
   is $resp->{content}, "here comes $path\n", "content looks good from regular route";
}
