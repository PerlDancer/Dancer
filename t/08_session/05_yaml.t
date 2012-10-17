use Test::More import => ['!pass'];

use strict;
use warnings;
use Dancer ':syntax';
use Dancer::ModuleLoader;
use Dancer::Logger;
use File::Path qw(mkpath rmtree);

# use t::lib::TestUtils;
# use t::lib::EasyMocker;

BEGIN {
    plan skip_all => "need YAML"
        unless Dancer::ModuleLoader->load('YAML');
    plan skip_all => "File::Temp 0.22 required"
        unless Dancer::ModuleLoader->load( 'File::Temp', '0.22' );
    plan tests => 12;
    use_ok 'Dancer::Session::YAML'
}

my $dir = File::Temp::tempdir(CLEANUP => 1, TMPDIR => 1);
set appdir => $dir;
my $session_dir = path($dir, "sessions_$$");
set session_dir => $session_dir;

my $session = Dancer::Session::YAML->create();
isa_ok $session, 'Dancer::Session::YAML';

ok( defined( $session->id ), 'ID is defined' );

is( Dancer::Session::YAML->retrieve('XXX'),
    undef, "unknown session is not found" );

my $s = Dancer::Session::YAML->retrieve( $session->id );
is_deeply $s, $session, "session is retrieved";

is_deeply( Dancer::Session::YAML->retrieve( $session->id ),
    $session->retrieve( $session->id ) );

my $yaml_file = $session->yaml_file;
like $yaml_file, qr/\.yml$/, 'session file have valid name';

$session->{foo} = 42;
$session->flush;
$s = Dancer::Session::YAML->retrieve( $s->id );
is_deeply $s, $session, "session is changed on flush";

my $id = $s->id;
$s->destroy;
$session = Dancer::Session::YAML->retrieve($id);
is $session, undef, 'session is destroyed';

ok( -d $session_dir, "session dir was created");
rmtree($session_dir);
eval { $session = Dancer::Session::YAML->create() };
my $error = $@;
like(
    $@,
    qr{Error in tempfile\(\) using .* Parent directory .* does not exist at.*},
    'session dir was not recreated',
);

Dancer::Session::YAML->reset();
$session = Dancer::Session::YAML->create();
ok( -d $session_dir, "session dir was recreated");
