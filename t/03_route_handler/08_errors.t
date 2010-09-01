use Test::More 'no_plan', import => ['!pass'];

use strict;
use warnings;

use Dancer ':syntax';
use Dancer::Error;
use Dancer::ModuleLoader;

my $error = Dancer::Error->new(code => 500);
ok(defined($error), "error is defined");
ok($error->title, "title is set");

if ( Dancer::ModuleLoader->load('JSON') ) {
    setting 'serializer' => 'JSON';
    my $error = Dancer::Error->new( code => 400, message => { foo => 'bar' } );
    ok( defined($error), "error is defined" );
    my $response = $error->render();
    isa_ok $response, 'Dancer::Response';
    is $response->{status},    400;
    like $response->{content}, qr/foo/;
}
