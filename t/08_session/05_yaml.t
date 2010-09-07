use Test::More import => ['!pass'];

use strict;
use warnings;
use Dancer ':syntax';
use Dancer::ModuleLoader;
use Dancer::Logger;

# use t::lib::TestUtils;
# use t::lib::EasyMocker;

use File::Temp qw/tempdir/;

BEGIN {
    plan skip_all => "need YAML"
        unless Dancer::ModuleLoader->load('YAML');
    plan tests => 9;
    use_ok 'Dancer::Session::YAML'
}


my $dir = tempdir(CLEANUP => 1);
set appdir => $dir;

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

File::Temp::cleanup();
