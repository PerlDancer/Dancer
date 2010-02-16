use Test::More tests => 9;

use strict;
use warnings;

use lib ('t');
use TestUtils;
use Dancer::Config 'setting';
setting appdir => 't/lib';

use_ok 'Dancer::Logger::File';

my $l = Dancer::Logger::File->new;

ok defined($l), 'Dancer::Logger::File object';
isa_ok $l, 'Dancer::Logger::File';
can_ok $l, qw(init _log debug warning error);

my $format = Dancer::Logger::File::_format('debug', 'test');
like $format, qr/\[$$\] \(debug\) test in/,
    "format looks good";

ok($l->_log(debug => "Perl Dancer test message"), "_log works");
ok($l->debug("Perl Dancer test message 2/4"), "debug works");
ok($l->warning("Perl Dancer test message 3/4"), "warning works");
ok($l->error("Perl Dancer test message 4/4"), "error works");

clean_tmp_files();
