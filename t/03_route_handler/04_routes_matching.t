use Dancer ':syntax';
use Dancer::Test;
use Test::More tests => 47, import => ['!pass'];

# regexps
{

    get qr{/hello/([\w]+)} => sub { [splat] };
    get qr{/show/([\d]+)}  => sub { [splat] };
    get qr{/post/([\w\d\-\.]+)/#comment([\d]+)} => sub { [splat] };

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

        response_status_is         $request => 200,
          "route handler found for path `$path'";
        response_content_is_deeply $request => $expected,
          "match data for path `$path' looks good";
    }

    response_status_is [GET => '/no/hello/bar'] => 404;
}

# passing
{
    get '/say/:char' => sub {
        pass and return false if length( params->{char} ) > 1;
        "char: " . params->{char};
    };

    get '/say/:number' => sub {
        pass and return false if params->{number} !~ /^\d+$/;
        "number: " . params->{number};
    };

    get qr{/say/_(.*)} => sub {
        "underscore: " . params->{splat}[0];
    };

    get '/say/:word' => sub {
        pass and return false if params->{word} =~ /trash/;
        "word: " . params->{word};
    };

    get '/say/*' => sub {
        "trash: " . params->{splat}[0];
    };

    get '/foo/' => sub { pass };

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

        response_status_is [ GET => $path ] => 200,
          "route found for path `$path'";
        response_content_is_deeply [ GET => $path ] => $expected,
          "match data for path `$path' looks good";
    }

    response_status_is [ GET => '/foo' ] => 404,
      "Pass over the last match is 404";
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

    get( $_ => sub { [splat] } ) for @paths;

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
    any [ 'get', 'delete' ] => '/any_1' => sub { "any_1"; };
    any '/any_2' => sub { "any_2"; };

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
                "route handler found for method $method, path $route->{path}");
            is $response->content, $route->{expected}, "response content is ok";
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
            is( $response->status, 404,
                "route handler not found for method $method, path "
                  . $route->{path} );
        }
    }
}
