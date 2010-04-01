use strict;
use warnings;
use Test::More;

BEGIN {
    use Dancer::ModuleLoader;
    plan skip_all => "JSON is needed to run this test"
        unless Dancer::ModuleLoader->load('JSON');
    plan tests => 3;
}

use Dancer::Config 'setting';
use Dancer::Request;
use Dancer::Serializer;
use Dancer::Serializer::JSON;

setting serializer => 'JSON';

my $body = '{"foo":42}';
open my $in, '<', \$body;

my $env = {
        CONTENT_LENGTH => length($body),
        CONTENT_TYPE   => Dancer::Serializer::JSON->content_type,
        REQUEST_METHOD => 'PUT',
        SCRIPT_NAME    => '/',
        'psgi.input'   => $in,
};

my $expected_params = {
    foo  => '42',
};

my $req = Dancer::Request->new($env);
is $req->body, $body, "body is untouched";

my $processed_req = Dancer::Serializer->process_request($req);
is_deeply(scalar($processed_req->params('body')), $expected_params,
    "body request has been deserialized");
is $processed_req->params->{'foo'}, 42, "params have been updated";
