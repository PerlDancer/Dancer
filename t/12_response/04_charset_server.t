use Test::More;
use strict;
use warnings;
use Dancer::ModuleLoader;
use Dancer::Config 'setting';
use Encode;

plan skip_all => "LWP is needed for this test" 
    unless Dancer::ModuleLoader->load('LWP::UserAgent');
plan skip_all => "HTTP::Request::Common is needed for this test"
    unless Dancer::ModuleLoader->load('HTTP::Request::Common');
plan skip_all => "Test::TCP is needed for this test"
    unless Dancer::ModuleLoader->load("Test::TCP");

plan tests => 6;

Test::TCP::test_tcp(
    client => sub {
        my $port = shift;
        my $ua = LWP::UserAgent->new;
        my $req = HTTP::Request::Common::POST("http://127.0.0.1:$port/name", [ name => 'vasya' ]);
        my $res = $ua->request($req);
        
        is $res->content_type, 'text/html';
        ok !$res->content_type_charset;
        is $res->content, 'Your name: vasya';

        $req = HTTP::Request::Common::GET("http://127.0.0.1:$port/unicode");
        $res = $ua->request($req);

        is $res->content_type, 'text/html';
        is $res->content_type_charset, 'UTF-8';
        is $res->content, Encode::encode('utf-8', "cyrillic shcha \x{0429}");
    },
    server => sub {
        my $port = shift;

        use lib "t/lib";
        use TestApp;
        Dancer::Config->load;

        setting charset => 'utf-8';
        setting environment => 'production';
        setting port => $port;
        setting access_log => 0;
        Dancer->dance();
    },
);
