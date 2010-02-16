use Test::More tests => 8;

use strict;
use warnings;
use lib ('t');
use TestUtils;

use Dancer::Config 'setting';
setting appdir => 't/lib';

use Dancer::Config 'setting';
setting appdir => 't/lib';

use_ok 'Dancer::Logger';

my $engine = Dancer::Logger->logger;
ok !defined($engine), "engine not defined";

eval { Dancer::Logger->init('foo') };
like $@, qr/unknown logger engine 'foo'/,
    'unknown logger engine detected';

ok Dancer::Logger->init('file'), 'logger file initialized';


$engine = Dancer::Logger->logger;
isa_ok $engine, 'Dancer::Logger::File';

foreach my $method qw(debug warning error) {
    ok Dancer::Logger->$method("test"), "$method works";
}

clean_tmp_files();
