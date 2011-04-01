#!/usr/bin/env perl

use strict;
use warnings;

use Dancer ':syntax', ':tests';
use Dancer::Session::Simple;
use Test::More tests => 2;


my $Session_Name = Dancer::Session::Simple->session_name;

note "session_secure off"; {
    set session => "simple";
    session foo => "bar";

    my $session_cookie = Dancer::Cookies->cookies->{ $Session_Name };
    ok !$session_cookie->secure;
}


note "session_secure on"; {
    delete Dancer::Cookies->cookies->{ $Session_Name };

    set session         => "simple";
    set session_secure  => 1;

    session up => "down";

    my $session_cookie = Dancer::Cookies->cookies->{ $Session_Name };
    ok $session_cookie->secure;
}
