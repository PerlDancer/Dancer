use Test::More import => ['!pass'];
use strict;
use warnings;
use Scalar::Util 'blessed';

use Dancer ':tests';
use Dancer::Test;
use Dancer::Serializer::YAML;

BEGIN {
    plan skip_all => 'YAML or YAML::XS is needed to run this test'
      unless Dancer::ModuleLoader->load('YAML::XS')
        or Dancer::ModuleLoader->load('YAML');
}

# YAML tags can ask the loader to build things that are not data. The two that
# matter for a serializer fed untrusted request bodies are:
#
#   !!perl/hash:Some::Class   instantiate an arbitrary blessed object, which is
#                             the entry point for DESTROY/AUTOLOAD gadget chains
#   !!perl/code               string-eval a sub body
#
# Dancer::Serializer::YAML::deserialize refuses both by setting the load
# toggles to 0 itself, rather than relying on the module's ambient defaults.
# That distinction is the point of these tests: the variables are localised
# inside deserialize, so the guarantee has to hold even when the surrounding
# process has set them to something hostile. Each test below therefore sets
# the ambient values to 1 first -- and in BOTH namespaces, since YAML.pm reads
# the YAML:: variables while YAML::XS reads its own YAML::XS:: variables, and
# the configured module may be either.
#
# The assertions deliberately test only the security property -- "no
# Attacker::Gadget object comes back" -- and not the exact shape of what does.
# That shape is module/version-dependent: with LoadBlessed off, YAML 1.30 and
# earlier silently strip the tag and return a plain hash, while newer YAML
# rejects the document outright. Both satisfy the guarantee.

# Use YAML::XS if available, like the other serializer tests do.
Dancer::ModuleLoader->load('YAML::XS')
    and config->{engines}->{YAML}->{module} = 'YAML::XS';

my $blessed_payload = q{--- !!perl/hash:Attacker::Gadget
foo: bar
};

my $serializer = Dancer::Serializer::YAML->new;

subtest 'a blessing tag never yields the attacker-named object' => sub {
    no warnings 'once';
    local $YAML::LoadBlessed      = 1;
    local $YAML::LoadCode         = 1;
    local $YAML::UseCode          = 1;
    local $YAML::XS::LoadBlessed  = 1;
    local $YAML::XS::LoadCode     = 1;
    local $YAML::XS::UseCode      = 1;

    my $data = eval { $serializer->deserialize($blessed_payload) };

    ok !( blessed($data) && $data->isa('Attacker::Gadget') ),
        'deserialize did not return an Attacker::Gadget object'
        or diag 'got: ' . ( blessed($data) || ref($data) || 'undef' );

    # Sanity check on the payload itself: with the guard bypassed it really
    # does bless. Without this, the assertion above would also pass on a
    # loader that could not bless at all, and would prove nothing.
    my $module = config->{engines}->{YAML}->{module} || 'YAML';
    no strict 'refs';
    my $direct = eval { &{ $module . '::Load' }($blessed_payload) };
    use strict 'refs';
    ok( blessed($direct) && $direct->isa('Attacker::Gadget'),
        'control: the payload blesses when passed straight to the loader' )
        or diag 'control got: ' . ( blessed($direct) || ref($direct) || 'undef' );
};

subtest 'the localisation does not leak' => sub {
    no warnings 'once';
    local $YAML::LoadBlessed      = 1;
    local $YAML::LoadCode         = 1;
    local $YAML::UseCode          = 1;
    local $YAML::XS::LoadBlessed  = 1;
    local $YAML::XS::LoadCode     = 1;
    local $YAML::XS::UseCode      = 1;

    eval { $serializer->deserialize($blessed_payload) };

    is $YAML::LoadBlessed,     1, 'an ambient YAML::LoadBlessed is restored';
    is $YAML::LoadCode,        1, 'an ambient YAML::LoadCode is restored';
    is $YAML::UseCode,         1, 'an ambient YAML::UseCode is restored';
    is $YAML::XS::LoadBlessed, 1, 'an ambient YAML::XS::LoadBlessed is restored';
    is $YAML::XS::LoadCode,    1, 'an ambient YAML::XS::LoadCode is restored';
    is $YAML::XS::UseCode,     1, 'an ambient YAML::XS::UseCode is restored';
};

subtest 'ordinary YAML still round-trips' => sub {
    my $data = { name => 'dancer', list => [ 1, 2, 3 ], nested => { a => 'b' } };
    my $out  = $serializer->deserialize( $serializer->serialize($data) );

    is_deeply $out, $data, 'a normal structure survives a round trip unchanged';
};

subtest 'a blessing payload sent as a request body never blesses' => sub {
    # As above, the ambient values are made hostile first; dancer_response runs
    # the app in this process, so this localisation is what the serializer sees.
    no warnings 'once';
    local $YAML::LoadBlessed      = 1;
    local $YAML::LoadCode         = 1;
    local $YAML::UseCode          = 1;
    local $YAML::XS::LoadBlessed  = 1;
    local $YAML::XS::LoadCode     = 1;
    local $YAML::XS::UseCode      = 1;

    setting serializer => 'mutable';

    post '/echo' => sub {
        my $body = params('body');
        return {
            is_gadget => ( blessed($body) && blessed($body) eq 'Attacker::Gadget' ) ? 1 : 0,
            ref       => ref($body) || 'none',
        };
    };

    my $res = dancer_response(
        POST => '/echo',
        {
            body         => $blessed_payload,
            content_type => 'text/x-yaml',
            headers      => [ 'Content-Type' => 'text/x-yaml' ],
        }
    );

    # 200 (older loaders strip the tag, route sees a plain hash) or a clean
    # 4xx/5xx (newer loaders reject the document) are both acceptable. What
    # must never happen is an Attacker::Gadget reaching the route or the
    # class name surfacing in the response.
    unlike $res->content, qr/Attacker::Gadget/,
        'no blessed gadget leaked into the response';

    if ( $res->status == 200 ) {
        my $out = $serializer->deserialize( $res->content );
        is $out->{is_gadget}, 0, 'the route saw an unblessed value';
    }
    else {
        ok $res->status >= 400,
            'a rejected body produced an error status, not a gadget';
    }
};

done_testing;