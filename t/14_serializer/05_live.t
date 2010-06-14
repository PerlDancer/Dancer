use strict;
use warnings;
use Test::More import => ['!pass'];

BEGIN {
    use Dancer::ModuleLoader;

    plan skip_all => "LWP::UserAgent is needed to run this tests"
        unless Dancer::ModuleLoader->load('LWP::UserAgent');
    plan skip_all => 'Test::TCP is needed to run this test'
        unless Dancer::ModuleLoader->load('Test::TCP');
    plan skip_all => 'YAML is needed to run this test'
        unless Dancer::ModuleLoader->load('YAML');
    plan skip_all => 'JSON is needed to run this test'
        unless Dancer::ModuleLoader->load('JSON');
    plan skip_all => 'HTTP::Request is needed to run this test'
        unless Dancer::ModuleLoader->load('HTTP::Request');
}

use Dancer;

my $content_types = {
    'YAML' => 'text/x-yaml',
    'JSON' => 'application/json',
};

test_json();
test_yaml();
test_mutable();

sub test_json {
    return unless Dancer::ModuleLoader->load('JSON');
    ok( setting( 'serializer' => 'JSON' ), "serializer JSON loaded" );

    Test::TCP::test_tcp(
        client => sub {
            my $port = shift;
            my $url  = "http://127.0.0.1:$port/";
            my $req  = HTTP::Request->new( GET => $url );
            $req->header( 'Content-Type' => 'application/json' );
            my $ua  = LWP::UserAgent->new;
            my $res = $ua->request($req);
            is_deeply(
                JSON::decode_json( $res->content ),
                { foo => 1 },
                "data is correctly serialized"
            );
            is $res->header('Content-Type'), 'application/json',
                "content type is OK";

            $req = HTTP::Request->new( POST => $url );
            $req->header( 'Content-Type' => 'application/json' );
            $req->content( JSON::encode_json( { foo => 1 } ) );
            $ua  = LWP::UserAgent->new;
            $res = $ua->request($req);
            is_deeply(
                JSON::decode_json( $res->content ),
                { foo => 1 },
                "data is correctly deserialized"
            );
            is $res->headers->{'content-type'}, 'application/json',
                'goodcontent type set in response';
        },
        server => sub {
            my $port = shift;
            use t::lib::TestSerializer;
            Dancer::Config->load;
            setting access_log => 0;
            setting port       => $port;
            Dancer->dance();
        },
    );
}

sub test_yaml {
    return unless Dancer::ModuleLoader->load('YAML');

    ok( setting( 'serializer' => 'YAML' ), "serializer YAML loaded" );
    Test::TCP::test_tcp(
        client => sub {
            my $port = shift;
            my $url  = "http://127.0.0.1:$port/";
            my $req  = HTTP::Request->new( GET => $url );
            $req->header( 'Content-Type' => 'text/x-yaml' );
            my $ua  = LWP::UserAgent->new;
            my $res = $ua->request($req);
            is_deeply(
                YAML::Load( $res->content ),
                { foo => 1 },
                "data is correctly serialized"
            );
            is $res->header('Content-Type'), 'text/x-yaml',
                "content type is OK";

            $req = HTTP::Request->new( POST => $url );
            $req->header( 'Content-Type' => 'text/x-yaml' );
            $req->content( YAML::Dump( { foo => 1 } ) );
            $ua  = LWP::UserAgent->new;
            $res = $ua->request($req);
            is_deeply(
                YAML::Load( $res->content ),
                { foo => 1 },
                "data is correctly deserialized"
            );
            is $res->headers->{'content-type'}, 'text/x-yaml',
                'goodcontent type set in response';
        },
        server => sub {
            my $port = shift;
            use t::lib::TestSerializer;
            Dancer::Config->load;
            setting port       => $port;
            setting access_log => 0;
            Dancer->dance();
        },
    );
}

sub test_mutable {
    return
        unless ( Dancer::ModuleLoader->load('YAML')
        && Dancer::ModuleLoader->load('JSON') );
    ok( setting( 'serializer' => 'Mutable' ), "serializer Mutable loaded" );
    Test::TCP::test_tcp(
        client => sub {
            my $port = shift;
            my $url  = "http://127.0.0.1:$port/";

            for my $ct (qw/Accept Accept-Type/) {
                my $req = HTTP::Request->new(GET => $url);
                $req->header($ct => 'application/json');
                my $ua  = LWP::UserAgent->new;
                my $res = $ua->request($req);
                is_deeply(
                    JSON::decode_json($res->content),
                    {foo => 1},
                    "data is correctly serialized"
                );
                is $res->header('Content-Type'), 'application/json',
                  "content type is OK";
            }

            my $req = HTTP::Request->new( POST => $url );
            $req->header('Content-Type' => 'text/x-yaml');
            $req->header('Accept-Type' => 'application/json');
            $req->content( YAML::Dump( { foo => 42 } ) );
            my $ua  = LWP::UserAgent->new;
            my $res = $ua->request($req);
            is_deeply(
                YAML::Load( $res->content ),
                { foo => 42 },
                "data is correctly deserialized"
            );
            is $res->headers->{'content-type'}, 'text/x-yaml',
                'goodcontent type set in response';
        },
        server => sub {
            my $port = shift;
            use t::lib::TestSerializer;
            Dancer::Config->load;
            setting port       => $port;
            setting access_log => 0;
            Dancer->dance();
        },
    );
}

done_testing;
