use Test::More 'no_plan', import => ['!pass'];

use strict;
use warnings;

use Dancer ':syntax';
use Dancer::Test;
use Dancer::Error;
use Dancer::ModuleLoader;

set show_errors => 1;

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

    # FIXME: i think this is a bug where serializer cannot be set to 'undef'
    # without the Serializer.pm trying to load JSON as a default serializer

    ##  Error Templates

    set serializer => undef;
    set warnings => 1;
    set error_template => "error.tt";
    set views => path(dirname(__FILE__), 'views');

    ok(get('/warning' => sub { my $a = undef; @$a; }), "/warning route defined");

    ok(get('/warning/:param' => sub { my $a = undef; @$a; }), "/warning route with params defined");

    response_content_like [GET => '/warning'],
      qr/ERROR: Runtime Error/,
      "template is used";

    response_content_like [GET => '/warning'],
      qr/PERL VERSION: $]/, "perl_version is available";

    response_content_like [GET => '/warning'],
      qr/DANCER VERSION: $Dancer::VERSION/, "dancer_version is available";

    response_content_like [GET => '/warning'],
      qr/ERROR TEMPLATE: error.tt/, "settings are available";

    response_content_like [GET => '/warning'],
      qr/REQUEST METHOD: GET/, "request is available";

    response_content_like [GET => '/warning/value'],
      qr/PARAM VALUE: value/, "params are available";
}

