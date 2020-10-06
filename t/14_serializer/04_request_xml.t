use Test::More import => ['!pass'];
use strict;
use warnings;
use Dancer ':tests';
use Dancer::ModuleLoader;
use Dancer::Test;

use File::Temp qw(tempfile);
use HTTP::Tiny::NoProxy;
use HTTP::Server::Simple::PSGI;
use Plack::Builder;

my $num_tests = 11;

plan tests => $num_tests;

SKIP: {
    skip 'XML::Simple is needed to run this test', $num_tests
      unless Dancer::ModuleLoader->load('XML::Simple');

    skip 'XML::Parser or XML::SAX are needed to run this test', $num_tests
        unless Dancer::ModuleLoader->load('XML::Parser') or
               Dancer::ModuleLoader->load('XML::SAX');

    set serializer => 'XML', show_errors => 1;

    get '/'          => sub { { foo => 'bar' } };
    post '/'         => sub { request->params };
    get '/error'     => sub { send_error( { foo => 42 }, 401 ) };
    get '/error_bis' => sub { send_error( 42, 402 ) };
    get '/xml'       => sub {
        content_type('text/xml');
        to_xml( { foo => 'bar' } )
    };

    for my $route ( '/', '/xml' ) {
        my $res = dancer_response( GET => $route );
        is $res->header('Content-Type'), 'text/xml';
        like $res->content, qr/<data foo="bar" \/>/;
    }

    my $res = dancer_response(
        POST => '/',
        {
            params  => { foo            => 1 },
            headers => [ 'Content-Type' => 'text/xml' ]
        }
    );
    is_deeply(
        from_xml( $res->content ),
        { foo => 1 },
        "data is correctly deserialized"
    );
    is $res->header('Content-Type'), 'text/xml',
      'goodcontent type set in response';

    $res = dancer_response( GET => '/error' );
    is $res->status, 401;
    is_deeply( from_xml($res->content ), { foo => 42 } );

    $res = dancer_response( GET => '/error_bis' );
    is $res->status, 402;
    is_deeply( from_xml( $res->content ), { error => 42 } );

    # This next test requires us to set up a separate server that we'll
    # hope cunningly-crafted XML doesn't call.
    # FIXME: this was cut and pasted from 24_deployment/01_multi_webapp.t
    # and should be refactored.
    skip "skip test with Test::TCP in win32", 1 if $^O eq 'MSWin32';
    skip "Test::TCP is needed to run this test", 1
        unless Dancer::ModuleLoader->load('Test::TCP' => "1.30");
    skip "Plack is needed to run this test", 1
        unless Dancer::ModuleLoader->load('Plack::Builder');

    # Test::TCP will fork, so we need a temporary file to put shared
    # information.
    my ($temp_fh, $tempfile)
        = tempfile('14_serializer_04_request_xml_XXXXX', TMPDIR => 1);
    Test::TCP::test_tcp(
        client => sub {
            my $port = shift;

            my $ua = HTTP::Tiny::NoProxy->new();
            my $res = $ua->get("http://127.0.0.1:$port/");
            $res = dancer_response(
                POST => '/',
                {
                    content_type => 'text/xml',
                    headers => ['Content-Type' => 'text/xml'],
                    body         => <<XXE_SSRF });
<?xml version="1.0" encoding="utf-8"?>
<!DOCTYPE wossname [
   <!ENTITY xxe SYSTEM "http://127.0.0.1:$port/" >
]>
<xml>
<xxx>
    &xxe;
</xxx>
</xml>
XXE_SSRF
        },
        server => sub {
            my $port = shift;

            my $app = sub {
                my $env = shift;
                open (my $fh, '>>', $tempfile);
                print $fh "Accessed at " . localtime(time) . "\n";
                close $fh;
                return [200, undef, ['Sure, whatever']];
            };

            $app = builder {
                mount "/" => builder { $app }
            };

            my $server = HTTP::Server::Simple::PSGI->new($port);
            $server->host("127.0.0.1");
            $server->app(builder { $app });
            $server->run;
        },
    );
          
    # XML crafted to call an arbitrary route *from our server*
    # is rejected: we know that the route we set up was called once, by us,
    # deliberately, but it wasn't called as a side-effect of the XML containing
    # an entity that was supposedly "defined" by that URL.
    my @access_lines;
    {
        open (my $fh, '<', $tempfile);
        @access_lines = <$fh>;
        close $fh;
    }
    is(scalar @access_lines, 1,
        'No XXE SSRF vulnerability in our XML handling');
    # for some reason we're seeing the same line in @access_lines 4 times instead of once, like:
    # "Accessed at Fri Sep 25 12:02:29 2020"

    diag( map { "access_line: $_" } @access_lines );
}
