use Test::More import => ['!pass'];
use strict;
use warnings;

BEGIN {
    use Dancer::ModuleLoader;

    plan skip_all => "skip test with Test::TCP in win32" if $^O eq 'MSWin32';

    plan skip_all => 'Test::TCP is needed to run this test'
        unless Dancer::ModuleLoader->load('Test::TCP' => "1.30");
    plan skip_all => 'YAML is needed to run this test'
        unless Dancer::ModuleLoader->load('YAML');
    plan skip_all => "File::Temp 0.22 required"
        unless Dancer::ModuleLoader->load( 'File::Temp', '0.22' );
}

use HTTP::Tiny::NoProxy;
use HTTP::CookieJar;

use File::Spec;
my $tempdir = File::Temp::tempdir(CLEANUP => 1, TMPDIR => 1);

use Dancer;
use Dancer::Logger;
 
my @clients = qw(one two three);
my @engines = qw(Simple YAML);

if ($ENV{DANCER_TEST_COOKIE}) {
    push @engines, "cookie";
    setting(session_cookie_key => "secret/foo*@!");
}

# Support testing with Dancer::Session::DBI if explictly told to by being
# provided with DB connection details via env vars (the appropriate table would
# have to have been created, too)
if ($ENV{DANCER_TEST_SESSION_DBI_DSN}) {
    push @engines, "DBI";
    setting(
        session_options => {
            dsn      => $ENV{DANCER_TEST_SESSION_DBI_DSN},
            user     => $ENV{DANCER_TEST_SESSION_DBI_USER},
            password => $ENV{DANCER_TEST_SESSION_DBI_PASS},
            table    => $ENV{DANCER_TEST_SESSION_DBI_TABLE},
        }
    );
}


plan tests => 13 * scalar(@clients) * scalar(@engines) + (scalar(@engines));

foreach my $engine (@engines) {

Test::TCP::test_tcp(
    client => sub {
        my $port = shift;

        foreach my $client (@clients) {
            my $ua = HTTP::Tiny::NoProxy->new(cookie_jar => HTTP::CookieJar->new);

            my $res = $ua->get("http://127.0.0.1:$port/read_session");
            like $res->{content}, qr/name=''/, 
            "empty session for client $client";

            $res = $ua->get("http://127.0.0.1:$port/set_session/$client");
            ok($res->{success}, "set_session for client $client");

            $res = $ua->get("http://127.0.0.1:$port/read_session");
            like $res->{content}, qr/name='$client'/,
            "session looks good for client $client";

            $res = $ua->get("http://127.0.0.1:$port/session/after_hook/read");
            ok($res->{success}, "Reading a session var in after hook worked");
            is(
                $res->{content},
                "Read value set in route",
                "Session var read in after hook and returned",
            );

            $res = $ua->get("http://127.0.0.1:$port/session/after_hook/write");
            ok($res->{success}, "writing a session var in after hook worked");
            is(
                $res->{content},
                "Read value changed in hook",
                "Session var set changed in hook successfully",
            );

            # Now read once more, to make sure that the session var set in the
            # after hook in the last test was actually persisted:
            $res = $ua->get("http://127.0.0.1:$port/session/after_hook");
            ok($res->{success}, "Fetched the session var");
            is(
                $res->{content},
                "value changed in hook",
                "Session var set in hook persisted",
            );

            $res = $ua->get("http://127.0.0.1:$port/session/after_hook/send_file");
            ok(
                $res->{success},
                "after hook accessing session after send_file doesn't explode"
                . " (GH #1205)",
            );
            is(
                $res->{content},
                "Hi there, random person (after hook fired)",
                "send_file route sent expected content and no explosion",
            );

            # Now destroy the session (e.g. logging out)
            $res = $ua->get("http://127.0.0.1:$port/session/destroy");
            ok(
                $res->{success},
                "called session destroy route",
            );
            # ... and the previous session has indeed gone
            my $res = $ua->get("http://127.0.0.1:$port/read_session");
            like $res->{content}, qr/name=''/, 
            "empty session for client $client after destroy";


        }
    },
    server => sub {
        my $port = shift;

        use File::Spec;
        use lib File::Spec->catdir( 't', 'lib' );
        use TestApp;
        Dancer::Config->load;

        setting appdir => $tempdir;
        Dancer::Logger->init('File');
        ok(setting(session => $engine), "using engine $engine");
        setting(log => "debug");
        setting(logger => "console");
        set( show_errors  => 1,
             startup_info => 0,
             environment  => 'production',
             port         => $port,
             server       => '127.0.0.1' );
        Dancer->dance();
    },
);
}

