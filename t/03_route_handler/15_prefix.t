use Test::More import => ['!pass'];
use t::lib::TestUtils;

plan tests => 23;

use Dancer ':syntax';
use Dancer::Route;

eval { prefix 'say' };
like $@, qr/not a valid prefix/i, 'prefix must start with a /';

ok( prefix '/say', 'prefix defined' );

ok(
    get(
        '/:char' => sub {
            pass and return false if length( params->{char} ) > 1;
            "char: " . params->{char};
        }
    ),
    'route /say/:char defined'
);

ok(
    get(
        '/:number' => sub {
            pass and return false if params->{number} !~ /^\d+$/;
            "number: " . params->{number};
        }
    ),
    'route /say/:number defined'
);

ok( any( '/any' => sub {"any"} ), 'route any /any defined' );

ok(
    get(
        { regexp => '/_(.*)' } => sub {
            "underscore: " . params->{splat}[0];
        }
    ),
    'route /say/_(.*) defined'
);

ok(
    get(
        '/:word' => sub {
            pass and return false if params->{word} =~ /trash/;
            "word: " . params->{word};
        }
    ),
    'route /:word defined'
);


ok( prefix undef );

ok(
    get(
        '/*' => sub {
            "trash: " . params->{splat}[0];
        }
    ),
    'route /say/* defined'
);

my @tests = (
    { path => '/say/A',       expected => 'char: A' },
    { path => '/say/24',      expected => 'number: 24' },
    { path => '/say/B',       expected => 'char: B' },
    { path => '/say/Perl',    expected => 'word: Perl' },
    { path => '/say/_stuff',  expected => 'underscore: stuff' },
    { path => '/say/any',     expected => 'any' },
    { path => '/go_to_trash', expected => 'trash: go_to_trash' },
);

foreach my $test (@tests) {
    my $path     = $test->{path};
    my $expected = $test->{expected};

    my $request = fake_request( GET => $path );
    Dancer::SharedData->request($request);

    my $response = Dancer::Renderer::get_action_response();

    ok( defined($response), "route found for path `$path'" );
    is_deeply( $response->{content}, $expected,
        "match data for path `$path' looks good" );
}
