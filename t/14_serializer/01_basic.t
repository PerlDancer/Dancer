use strict;
use warnings;
use Test::More import => ['!pass'];

plan tests => 6;

use Dancer ':syntax';
use Dancer::Response;
use Dancer::Request;
use Dancer::ModuleLoader;
use Dancer::FileUtils 'read_glob_content';

use_ok 'Dancer::Serializer';

setting public => path(dirname(__FILE__), 'public');
setting show_errors => 1;

my $response = Dancer::Response->new(status => 200, content => {foo => 'bar'});

ok my $content = Dancer::Serializer->process_response($response);
is $content->{status}, 500, "can't serialize without serializer defined";
like $content->{content}, qr/failed at serializing/, "Error message is set";

my $body = 'foo=bar';
open my $in, '<', \$body;

%ENV = (
          'REQUEST_METHOD' => 'POST',
          'REQUEST_URI' => '/',
          'PATH_INFO' => '/',
          'CONTENT_TYPE' => 'application/json',
          'psgi.input'   => $in,
          );

my $req = Dancer::Request->new( \%ENV );

$response = Dancer::Serializer->process_request($req);
is_deeply $response, $req;

SKIP: {
    skip "JSON is required", 1, unless Dancer::ModuleLoader->load('JSON');
    my $serializer = Dancer::Serializer->init;
    my $res        = Dancer::Serializer->process_request($req);
    is_deeply $req, $res,
      'request and response are the same, impossible to deserialize';
};
