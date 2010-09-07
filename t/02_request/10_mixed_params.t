use Test::More import => ['!pass'];
use strict;
use warnings;

use Dancer ':syntax';
use Dancer::ModuleLoader;

plan skip_all => "LWP is needed for this test" 
    unless Dancer::ModuleLoader->load('LWP::UserAgent');
plan skip_all => "Test::TCP is needed for this test"
    unless Dancer::ModuleLoader->load("Test::TCP");

plan tests => 2;
Test::TCP::test_tcp(
    client => sub {
        my $port = shift;
        my $ua = LWP::UserAgent->new;
        my $res = $ua->post("http://127.0.0.1:$port/params/route?a=1&var=query", {var =>
        'post', b => 2});
        
        ok $res->is_success, 'req is success';
        my $content = $res->content;
        my $VAR1;
        eval ("$content");

        my $expected = {
                params => {
                    a => 1, b => 2, 
                    var => 'post',
                },
                body => {
                    var => 'post',
                    b => 2
                },
                query => {
                    a => 1,
                    var => 'query'
                },
                route => {
                    var => 'route'
                }
        };
        is_deeply $VAR1, $expected, "parsed params are OK";
    },
    server => sub {
        my $port = shift;

        use t::lib::TestApp;
        Dancer::Config->load;

        setting environment => 'production';
        setting port => $port;
        setting access_log => 0;
        Dancer->dance();
    },
);
