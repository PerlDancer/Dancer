use Test::More import => ['!pass'];

use strict;
use warnings;
use Dancer ':syntax';
use Dancer::ModuleLoader;
use Dancer::Logger;
use Dancer::Config 'setting';

use t::lib::TestUtils;
use t::lib::EasyMocker;

use File::Temp qw/tempdir/;

BEGIN { 
    plan skip_all => "need YAML" 
        unless Dancer::ModuleLoader->load('YAML');
    plan tests => 12;
    use_ok 'Dancer::Session::YAML' 
}


my $dir = tempdir(CLEAN_UP => 1);
set appdir => $dir;
Dancer::Logger->init('File');

mock 'Dancer::ModuleLoader' 
    => method 'load' => should sub { 0 };

my $session;

eval { $session = Dancer::Session::YAML->create };
like $@, qr/YAML is needed/,
    "Need YAML";

# TODO : need a way to restore original sub
# in t::lib::EasyMocker
mock 'Dancer::ModuleLoader' 
    => method 'load' => should sub { 1 };

eval { $session = Dancer::Session::YAML->create };
is $@, '', "YAML session created";

isa_ok $session, 'Dancer::Session::YAML';
can_ok $session, qw(init create retrieve destroy flush);
ok(defined(setting('session_dir')), 'session_dir defined');

ok defined($session->id), 'session id is defined';

my $s = Dancer::Session::YAML->retrieve('XXX');
is $s, undef, "unknown session is not found";

$s = Dancer::Session::YAML->retrieve($session->id);
is_deeply $s, $session, "session is retrieved";

ok defined($s->yaml_file), 'yaml_file is found';
$s->{foo} = 42;
$s->flush;
$session = Dancer::Session::YAML->retrieve($session->id);
is_deeply $s, $session, "session is changed on flush";

$s->destroy;
$session = Dancer::Session::YAML->retrieve($session->id);
is $session, undef, 'destroy removes the session';
