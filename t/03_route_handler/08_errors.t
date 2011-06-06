use Test::More;
use Dancer ':syntax', ':tests';
use Dancer::Test;
use Dancer::Error;
use Dancer::ModuleLoader;

plan tests => 12;

set show_errors => 1;

my $error = Dancer::Error->new(code => 500);
ok defined($error) => "error is defined";
ok $error->title   => "title is set";

SKIP: {
    skip "JSON is required", 10 unless Dancer::ModuleLoader->load('JSON');
    set 'serializer' => 'JSON';
    my $error = Dancer::Error->new( code => 400, message => { foo => 'bar' } );
    ok defined($error) => "error is defined";

    my $response = $error->render();
    isa_ok $response => 'Dancer::Response';

    is     $response->{status}  => 400;
    like   $response->{content} => qr/foo/;

    # FIXME: i think this is a bug where serializer cannot be set to 'undef'
    # without the Serializer.pm trying to load JSON as a default serializer

    ##  Error Templates

    set(serializer => undef,
        warnings => 1,
        error_template => "error.tt",
        views => path(dirname(__FILE__), 'views'));

    get '/warning'        => sub { my $a = undef; @$a; };
    get '/warning/:param' => sub { my $a = undef; @$a; };

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
};

