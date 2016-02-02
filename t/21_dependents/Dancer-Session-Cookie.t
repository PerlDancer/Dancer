#!/usr/bin/env perl

use strict;
use warnings;

use Dancer::ModuleLoader;
use Test::More import => ['!pass'];

plan skip_all => "Dancer::Session::Cookie 0.14 required"
    unless Dancer::ModuleLoader->load( 'Dancer::Session::Cookie', '0.14' );

diag "Loaded Dancer::Session::Cookie version "
    . $Dancer::Session::Cookie::VERSION;

plan skip_all => "skip test with Test::TCP in win32" if $^O eq 'MSWin32';
plan skip_all => "Test::TCP required"
    unless Dancer::ModuleLoader->load('Test::TCP' => "1.30");
Test::TCP->import;

plan tests=> 7;

my $host = '127.0.0.10';
test_tcp(
    client => sub {
        my $port = shift;

        require HTTP::Tiny;
        require HTTP::CookieJar;

        my $ua = HTTP::Tiny->new;

        # Simulate two different browsers with two different jars
        my @jars = (HTTP::CookieJar->new, HTTP::CookieJar->new);
        for my $jar (@jars) {
            $ua->cookie_jar( $jar );

            my $res = $ua->get("http://$host:$port/foo");
            is $res->{content}, "hits: 0, last_hit: ";

            $res = $ua->get("http://$host:$port/bar");
            is $res->{content}, "hits: 1, last_hit: foo";

            $res = $ua->get("http://$host:$port/baz");
            is $res->{content}, "hits: 2, last_hit: bar";
        }

        $ua->cookie_jar($jars[0]);
        my $res = $ua->get("http://$host:$port/wibble");
        is $res->{content}, "hits: 3, last_hit: baz", "session not overwritten";
    },
    server => sub {
        my $port = shift;

        use Dancer ':tests';

        set( port                => $port,
             server              => $host,
             appdir              => '',          # quiet warnings not having an appdir
             startup_info        => 0,           # quiet startup banner
             session_cookie_key  => "John has a long mustache",
             session             => "cookie" );

        get "/*" => sub {
            my $hits = session("hit_counter") || 0;
            my $last = session("last_hit") || '';

            session hit_counter => $hits + 1;
            session last_hit => (splat)[0];

            return "hits: $hits, last_hit: $last";
        };

        dance;
    },
    host => $host,
);
