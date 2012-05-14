#!/usr/bin/env perl

use strict;
use warnings;

use Dancer ':syntax', ':tests';
use Dancer::Session::Simple;
use Test::More tests => 2;


my $Session_Name = Dancer::Session::Simple->session_name;

note "session_domain off"; {
    set session => "simple";
    session foo => "bar";

    my $session_cookie = Dancer::Cookies->cookies->{ $Session_Name };
    ok !$session_cookie->domain;
}


note "session_domain on"; {
    delete Dancer::Cookies->cookies->{ $Session_Name };

    my $test_domain = '.test-domain.com';

    set session         => "simple";
    set session_domain  => $test_domain;

    session up => "down";

    my $session_cookie = Dancer::Cookies->cookies->{ $Session_Name };
    is $session_cookie->domain => $test_domain;
}
