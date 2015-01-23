use Dancer ':syntax';
use Dancer::Test;
use Test::More 'tests' => 8, import => ['!pass'];

use Dancer::Route;

my $r = Dancer::Route->new(
    method => 'get',
    pattern => '/:var',
    code => sub {
        params->{'var'};
    },
);

isa_ok $r => 'Dancer::Route';

is $r->method  => 'get',   "method is 'get'";
is $r->pattern => '/:var', "pattern is '/:var'";

my $req = Dancer::Request->new_for_request(GET => '/42');
my $expected_match = { var => 42 };
my $match = $r->match($req);
is_deeply $match => $expected_match, "route matched GET /42";

$r->match_data($match);
Dancer::SharedData->request($req);
my $response = $r->run($req);
is $response->{content} => 42, "response looks good";

my $r2 = Dancer::Route->new(method => 'get',
    pattern => '/pass/:var',
    code => sub { pass;
                  # The next line is not executed, as 'pass' breaks the route workflow
                  die },
    prev => $r);

my $r3 = Dancer::Route->new(method => 'get',
    pattern => '/other/path',
    code => sub { "this is r3" },
    prev => $r2);


my $r4 = Dancer::Route->new(method => 'get',
    pattern => '/pass/:var',
    code => sub { "this is r4" },
    prev => $r3);

$req = Dancer::Request->new_for_request(GET => '/pass/42');
$expected_match = { var => 42 };
$match = $r2->match($req);
is_deeply $match => $expected_match, "route matched GET /42";

$r2->match_data($match);
Dancer::SharedData->request($req);
$r2->run($req);

$response = Dancer::SharedData->response;
is $response->{content} => 'this is r4',
    "route 2 passed, r3 skipped (don't match), r4 served the response";

setting 'public' => 't/03_route_handler/public';

my $r5 = Dancer::Route->new(
    method  => 'get',
    pattern => '/error',
    code    => sub { send_error( "no", 404 ) }
);
$req = Dancer::Request->new_for_request( GET => '/error' );
my $res = $r5->run($req);
is( ( grep { /Content-Type/ } @{ $res->headers_to_array } ),
    1, 'only one content-type' );
