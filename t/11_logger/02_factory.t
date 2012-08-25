use Test::More import => ['!pass'];

use strict;
use warnings;
use t::lib::TestUtils;

use Dancer ':syntax';

plan skip_all => "File::Temp 0.22 required"
    unless Dancer::ModuleLoader->load( 'File::Temp', '0.22' );

plan tests => 8;

my $dir = File::Temp::tempdir(CLEANUP => 1, TMPDIR => 1);
setting appdir => $dir;

use_ok 'Dancer::Logger';

my $engine = Dancer::Logger->logger;
ok !defined($engine), "engine not defined";

eval { Dancer::Logger->init('foo') };
like $@, qr/unable to load logger engine 'foo'/,
    'unknown logger engine detected';

ok(Dancer::Logger->init('file'), 'logger file initialized');


$engine = Dancer::Logger->logger;
isa_ok $engine, 'Dancer::Logger::File';

foreach my $method (qw(debug warning error)) {
    ok(Dancer::Logger->$method("test"), "$method works");
}

Dancer::Logger::logger->{fh}->close;
File::Temp::cleanup();
