# RT #57805
# https://rt.cpan.org/Ticket/Display.html?id=57805
#
# Serializer issue: params hash not populated when the Content-Type is a
# supported media type with additional parameters
use Test::More import => ['!pass'];
use strict;
use warnings;

# Requires
plan skip_all => 'Test::TCP is needed to run this test'
    unless Dancer::ModuleLoader->load('Test::TCP');
plan skip_all => "JSON needed for this test" 
    unless Dancer::ModuleLoader->load('JSON');

# Test
plan tests => 3;

use LWP::UserAgent;

Test::TCP::test_tcp(
    client => sub {
        my $port = shift;
        my $ua = LWP::UserAgent->new;

        # data we're going to pass through requests
        my $data = {foo => 42};

        for my $ct (
                'application/json', 
                'APPLICATION/JSON', 
                'application/json; charset=UTF-8') 
        {
            my $request = HTTP::Request->new(POST => "http://127.0.0.1:$port/test");
            $request->content(JSON::to_json({test_value => $data}));
            $request->header('Content-Type' => $ct);
            my $res = $ua->request($request);
            is_deeply(JSON::from_json($res->content), {test_value => $data}, 
                "correctly deserialized when Content-Type is set to '$ct'");
        }
    },
    server => sub {
        my $port = shift;
            
        use Dancer;
        
        set serializer => 'JSON';
        set port => $port;
        set show_errors => 1;
        set access_log => 0;

        post '/test' => sub {
            return { test_value => params->{test_value} };
        };
        
        dance();
    },
);

