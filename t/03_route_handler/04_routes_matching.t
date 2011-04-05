use strict;
use warnings;
use Test::More tests => 61, import => ['!pass'];

use Dancer;
use Dancer::Test;

# regexps
{

    ok( get( qr{/hello/([\w]+)} => sub { [splat] } ), 'first route set' );
    ok( get( qr{/show/([\d]+)}  => sub { [splat] } ), 'second route set' );
    ok( get( qr{/post/([\w\d\-\.]+)/#comment([\d]+)} => sub { [splat] } ),
        'third route set' );

    my @tests = (
        {
            path     => '/hello/sukria',
            expected => ['sukria']
        },

        {
            path     => '/show/245',
            expected => ['245']
        },

        {
            path     => '/post/this-how-to-write-smart-webapp/#comment412',
            expected => [ 'this-how-to-write-smart-webapp', '412' ]
        },
    );

    foreach my $test (@tests) {
        my $handle;
        my $path     = $test->{path};
        my $expected = $test->{expected};

        my $request = [ GET => $path ];

        response_exists( $request, "route handler found for path `$path'" );
        response_content_is_deeply( $request, $expected,
            "match data for path `$path' looks good" );
    }
}

# passing
{
    ok(
        get(
            '/say/:char' => sub {
                pass and return false if length( params->{char} ) > 1;
                "char: " . params->{char};
            }
        ),
        'route /say/:char defined'
    );

    ok(
        get(
            '/say/:number' => sub {
                pass and return false if params->{number} !~ /^\d+$/;
                "number: " . params->{number};
            }
        ),
        'route /say/:number defined'
    );

    ok(
        get(
            qr{/say/_(.*)} => sub {
                "underscore: " . params->{splat}[0];
            }
        ),
        'route /say/_(.*) defined'
    );

    ok(
        get(
            '/say/:word' => sub {
                pass and return false if params->{word} =~ /trash/;
                "word: " . params->{word};
            }
        ),
        'route /say/:word defined'
    );

    ok(
        get(
            '/say/*' => sub {
                "trash: " . params->{splat}[0];
            }
        ),
        'route /say/* defined'
    );

    ok( get( '/foo/' => sub { pass } ), "route /foo/ defined" );

    my @tests = (
        { path => '/say/A',           expected => 'char: A' },
        { path => '/say/24',          expected => 'number: 24' },
        { path => '/say/B',           expected => 'char: B' },
        { path => '/say/Perl',        expected => 'word: Perl' },
        { path => '/say/_stuff',      expected => 'underscore: stuff' },
        { path => '/say/go_to_trash', expected => 'trash: go_to_trash' },
    );

    foreach my $test (@tests) {
        my $path     = $test->{path};
        my $expected = $test->{expected};

        response_exists( [ GET => $path ], "route found for path `$path'" );
        response_content_is_deeply( [ GET => $path ],
            $expected, "match data for path `$path' looks good" );
    }

    response_status_is( [ GET => '/foo' ],
        404, "Pass over the last match is 404" );
}

# wildcards
{
    my @paths =
      ( '/hi/*', '/hi/*/welcome/*', '/download/*.*', '/optional/?*?' );

    my @tests = (
        {
            path     => '/hi/sukria',
            expected => ['sukria']
        },

        {
            path     => '/hi/alexis/welcome/sukrieh',
            expected => [ 'alexis', 'sukrieh' ]
        },

        {
            path     => '/download/wolverine.pdf',
            expected => [ 'wolverine', 'pdf' ]
        },

        { path => '/optional/alexis', expected => ['alexis'] },
        { path => '/optional/',       expected => [] },
        { path => '/optional',        expected => [] },
    );

    my $nb_tests = ( scalar(@paths) ) + ( scalar(@tests) * 2 );

    ok( get( $_ => sub { [splat] } ), "route $_ is set" ) for @paths;

    foreach my $test (@tests) {
        my $path     = $test->{path};
        my $expected = $test->{expected};

        my $response = dancer_response( GET => $path );

        ok( defined($response), "route handler found for path `$path'" );
        is_deeply( $response->content, $expected,
            "match data for path `$path' looks good" );
    }
}

# any routes handler
{
    eval {
        any [ 'get', 'delete' ] => '/any_1' => sub {
            "any_1";
        };
    };
    is $@, '', "route defined for methods get and delete; for path /any_1";

    eval {
        any '/any_2' => sub {
            "any_2";
        };
    };
    is $@, '', "route defined for any method; for path /any_1";

    eval {
        any 'get' => '/any_1' => sub {
            "any_1";
        };
    };
    like $@, qr/Syntax error, methods should be provided as an ARRAY ref/,
      "syntax error caught";

    my @routes = (
        {
            methods  => [ 'get', 'delete' ],
            path     => '/any_1',
            expected => 'any_1',
        },
        {
            methods  => [ 'get', 'delete', 'post', 'put' ],
            path     => '/any_2',
            expected => 'any_2',
        }
    );

    # making sure response are OK
    foreach my $route (@routes) {
        foreach my $method ( @{ $route->{methods} } ) {
            my $response = dancer_response( $method => $route->{path} );
            ok( defined($response),
                "route handler found for method $method, path "
                  . $route->{path} );
            is $response->content, $route->{expected},
              "response content is ok";
        }
    }

    # making sure 404 are thrown for unspecified routes
    my @failed = (
        {
            methods => [ 'post', 'put' ],
            path    => '/any_1',
        },
    );

    foreach my $route (@failed) {
        foreach my $method ( @{ $route->{methods} } ) {
            my $response = dancer_response( $method => $route->{path} );
            ok( !defined($response),
                "route handler not found for method $method, path "
                  . $route->{path} );
        }
    }

}
