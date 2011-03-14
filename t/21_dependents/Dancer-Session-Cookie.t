#!/usr/bin/env perl

use strict;
use warnings;

use Test::More import => ['!pass'];

plan skip_all => "Dancer::Session::Cookie required" unless eval {
    require Dancer::Session::Cookie;
};

plan skip_all => "Test::TCP required" unless eval {
    require Test::TCP; Test::TCP->import; 1;
};

plan skip_all => "HTTP::Cookies required" unless eval {
    require HTTP::Cookies; HTTP::Cookies->import; 1;
};

plan tests=> 7;

test_tcp(
    client => sub {
        my $port = shift;

        require LWP::UserAgent;
        require HTTP::Cookies;

        my $ua = LWP::UserAgent->new;

        # Simulate two different browsers with two different jars
        my @jars = (HTTP::Cookies->new, HTTP::Cookies->new);
        for my $jar (@jars) {
            $ua->cookie_jar( $jar );

            my $res = $ua->get("http://0.0:$port/foo");
            is $res->content, "hits: 0, last_hit: ";

            $res = $ua->get("http://0.0:$port/bar");
            is $res->content, "hits: 1, last_hit: foo";

            $res = $ua->get("http://0.0:$port/baz");
            is $res->content, "hits: 2, last_hit: bar";
        }

        $ua->cookie_jar($jars[0]);
        my $res = $ua->get("http://0.0:$port/wibble");
        is $res->content, "hits: 3, last_hit: baz", "session not overwritten";
    },
    server => sub {
        my $port = shift;

        use Dancer ':tests';

        set port                => $port;
        set appdir              => '';          # quiet warnings not having an appdir
        set access_log          => 0;           # quiet startup banner

        set session_cookie_key  => "John has a long mustache";
        set session             => "cookie";

        get "/*" => sub {
            my $hits = session("hit_counter") || 0;
            my $last = session("last_hit") || '';

            session hit_counter => $hits + 1;
            session last_hit => (splat)[0];

            return "hits: $hits, last_hit: $last";
        };

        dance;
    }
);
