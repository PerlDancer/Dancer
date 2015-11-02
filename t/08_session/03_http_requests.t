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

use LWP::UserAgent;

use File::Spec;
my $tempdir = File::Temp::tempdir(CLEANUP => 1, TMPDIR => 1);

use Dancer;
use Dancer::Logger;
 
my @clients = qw(one two three);
my @engines = qw(YAML);

if ($ENV{DANCER_TEST_COOKIE}) {
    push @engines, "cookie";
    setting(session_cookie_key => "secret/foo*@!");
}


plan tests => 3 * scalar(@clients) * scalar(@engines) + (scalar(@engines));

foreach my $engine (@engines) {

Test::TCP::test_tcp(
    client => sub {
        my $port = shift;

        foreach my $client (@clients) {
            my $ua = LWP::UserAgent->new;
            $ua->cookie_jar({ file => "$tempdir/.cookies.txt" });

            my $res = $ua->get("http://127.0.0.1:$port/read_session");
            like $res->content, qr/name=''/, 
            "empty session for client $client";

            $res = $ua->get("http://127.0.0.1:$port/set_session/$client");
            ok($res->is_success, "set_session for client $client");

            $res = $ua->get("http://127.0.0.1:$port/read_session");
            like $res->content, qr/name='$client'/,
            "session looks good for client $client";

        }

        File::Temp::cleanup();
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
        set( show_errors  => 1,
             startup_info => 0,
             environment  => 'production',
             port         => $port,
             server       => '127.0.0.1' );
        Dancer->dance();
    },
);
}

