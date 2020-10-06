use strict;
use warnings;
use Test::More import => ['!pass'];

use Dancer::ModuleLoader;
use Dancer;
use Dancer::Cookie;

plan skip_all => "skip test with Test::TCP in win32" if $^O eq 'MSWin32';
plan skip_all => "Test::TCP is needed for this test"
  unless Dancer::ModuleLoader->load("Test::TCP" => "1.30");
plan skip_all => "YAML is needed for this test"
  unless Dancer::ModuleLoader->load("YAML");


use HTTP::Tiny::NoProxy;
use File::Path 'rmtree';
use Dancer::Config;

my $session_dir = path( Dancer::Config::settings->{appdir}, "sessions_$$" );
set session_dir => $session_dir;

# Test with different values set for the session_same_site config option;
# each is an arrayref of the value to set session_same_site to, a boolean
# indicating whether we expect setting that value to be accepted, and a
# regex we expect the resulting cookie to match.
my @tests = (
    # Values which we expect to work (case insensitively)
    [ strict => 1, qr/SameSite=Strict/,  ],
    [ Lax    => 1, qr/SameSite=Lax/,      ],
    [ Strict => 1, qr/SameSite=Strict/,   ],
    # 'notset' is magic, simulates the option not being set at all
    [ notset => 1, qr/(?!SameSite)/,         ],
    # Invalid values will be rejected by Dancer::Config
    [ 'StrictlyComeDancing' => 0, qr/(?!SameSite)/, ],
    [ ''                    => 0, qr/(?!SameSite)/, ],
);

plan tests => 4 * @tests;

for my $test (@tests) {
    my ($setting, $setting_should_work, $regex) = @$test;
    Test::TCP::test_tcp(
        client => sub {
            my $port = shift;
            my $ua   = HTTP::Tiny::NoProxy->new;
            my $res = $ua->get("http://127.0.0.1:$port/set_session/test_13");
            ok $res->{success}, 'req is success';
            diag $res->{status};
            my $cookie = $res->{headers}{'set-cookie'};
            ok $cookie, 'cookie is set';
            diag "Cookie: $cookie";
            like $cookie, $regex, "With session_same_site '$setting', cookie "
                . "was as expected ($regex)";
        },
    server => sub {
        my $port = shift;

        use File::Spec;
        use lib File::Spec->catdir( 't', 'lib' );
        use TestApp;
        Dancer::Config->load;

        set( 
            session              => 'YAML',
            environment          => 'production',
            port                 => $port,
            server               => '127.0.0.1',
            startup_info         => 0,
        );
        SKIP: {
            if ($setting eq 'notset') {
                skip "Testing with setting unset", 1;
            } else {
                # We should try to set it; we may expect it to fail.
                eval { set session_same_site => $setting; };
                my $error = $@;
                ok(
                    ($setting_should_work && !$error)
                    ||
                    (!$setting_should_work && $error),
                    "Setting $setting "
                    . ($setting_should_work ? 'worked' : 'failed')
                    . ' as expected',
                );
            }
        }
        Dancer->dance();
        },
    );

}

# clean up after ourselves
rmtree($session_dir);

