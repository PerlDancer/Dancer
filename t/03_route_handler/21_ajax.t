use strict;
use warnings;
use Test::More import => ['!pass'];
use Dancer ':syntax';
use Dancer::Test;

plan skip_all => "skip test with Test::TCP in win32" if $^O eq 'MSWin32';
plan skip_all => 'Test::TCP is needed to run this test'
    unless Dancer::ModuleLoader->load('Test::TCP' => "1.30");

use HTTP::Tiny::NoProxy;

plan tests => 33;

ok(Dancer::App->current->registry->is_empty,
    "registry is empty");
ok(Dancer::Plugin::Ajax::ajax( '/', sub { "ajax" } ), "ajax helper called");
ok(!Dancer::App->current->registry->is_empty,
    "registry is not empty");

Test::TCP::test_tcp(
    client => sub {
        my $port = shift;
        my $ua = HTTP::Tiny::NoProxy->new;

        my @queries = (
            { path => 'req', ajax => 1, success => 1, content => 1 },
            { path => 'req', ajax => 0, success => 0 },
            { path => 'foo', ajax => 1, success => 1, content => 'ajax' },
            { path => 'foo', ajax => 0, success => 1, content => 'not ajax' },
            { path => 'bar', ajax => 1, success => 1, content => 'ajax' },
            { path => 'bar', ajax => 0, success => 1, content => 'not ajax' },
            { path => 'layout', ajax => 0, success => 1, content => 'wibble' },
            { path => 'die', ajax => 1, success => 0 },
            { path => 'layout', ajax => 0, success => 1, content => 'wibble' },
        );

        foreach my $query (@queries) {
            my %headers;
            $headers{'X-Requested-With'} = 'XMLHttpRequest'
              if ( $query->{ajax} == 1);

            ok my $res = $ua->get("http://127.0.0.1:$port/" . $query->{path}, { headers => \%headers });

            if ( $query->{success} == 1) {
                ok $res->{success};
                is $res->{content}, $query->{content};
                like $res->{headers}{'content-type'}, qr/text\/xml/ if $query->{ajax} == 1;
            }
            else {
                ok !$res->{success};
            }
        }

        # test ajax with content_type to json
        my %headers = ( 'X-Requested-With' => 'XMLHttpRequest' );
        ok my $res = $ua->get("http://127.0.0.1:$port/ajax.json", { headers => \%headers });
        like $res->{headers}{'content-type'}, qr/json/;
    },
    server => sub {
        my $port = shift;

        use Dancer;
        use Dancer::Plugin::Ajax;

        set startup_info => 0, port => $port, server => '127.0.0.1', layout => 'wibble';

        ajax '/req' => sub {
            return 1;
        };
        get '/foo' => sub {
            return 'not ajax';
        };
        ajax '/foo' => sub {
            return 'ajax';
        };
        get '/bar' => sub {
            return 'not ajax';
        };
        get '/bar', {ajax => 1} => sub {
            return 'ajax';
        };
        get '/ajax.json' => sub {
            content_type('application/json');
            return '{"foo":"bar"}';
        };
        ajax '/die' => sub {
            die;
        };
        get '/layout' => sub {
            return setting 'layout';
        };
        start();
    },
);
