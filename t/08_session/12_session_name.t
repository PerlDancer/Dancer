#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 7;
use Dancer ':syntax', ':tests';

set session => "simple";

note "changing session name"; {
    my $orig_name = setting("session_name");
    session foo => "bar";
    is session("foo"), "bar";

    set session_name => "something.else";
    is setting("session_name"), "something.else", "session_name changed";
    isnt session("foo"), "bar",                   "other session's values not seen";

    session up => "down";
    is session("up"), "down",                     "storing our values";

    set session_name => $orig_name;
    is setting("session_name"), $orig_name,       "set back to the original name";
    isnt session("up"), "down",                   "other session's values not seen";
    is session("foo"), "bar",                     "original value restored";
}

use File::Spec;
use lib File::Spec->catdir( 't', 'lib' );
use Dancer::Session::TestOverrideName;

#
# make sure that session code overrides session_name via object
# instead of configuration
#
{
    my $session = Dancer::Session::TestOverrideName->new;

    is $session->session_name, "dr_seuss", "session_name in driver";
}
