use Test::More import => ['!pass'];

use strict;
use warnings;

use t::lib::TestUtils;
use Dancer;

plan skip_all => "File::Temp 0.22 required"
    unless Dancer::ModuleLoader->load( 'File::Temp', '0.22' );

plan tests => 18;

my $dir = File::Temp::tempdir(CLEANUP => 1, TMPDIR => 1);
set appdir => $dir, environment => 'test';

use_ok 'Dancer::Logger::File';

my $l = Dancer::Logger::File->new;

ok defined($l), 'Dancer::Logger::File object';
isa_ok $l, 'Dancer::Logger::File';
can_ok $l, qw(init _log debug warning error);

my $format = $l->format_message('debug', 'test');
like $format, qr/\[\d+\] debug @.+> test in/,
    "format looks good";

ok($l->_log(debug => "Perl Dancer test message"), "_log works");
ok($l->debug("Perl Dancer test message 2/5"), "debug works");
ok($l->warning("Perl Dancer test message 3/5"), "warning works");
ok($l->error("Perl Dancer test message 4/5"), "error works");
ok($l->info("Perl Dancer test message 5/5"), "info works");

ok(-f path($dir,'logs','test.log'), "Log file exists");

#Create a new tmp directory to test log_path option
my $dir2 = File::Temp::tempdir(CLEANUP => 1, TMPDIR => 1);

set log_path => $dir2, log_file => "foo.bar";

is(Dancer::Logger::File->logdir, $dir2,
    "logdir is ok");

ok($l->_log(debug => "Perl Dancer test message with log_path setting"), "_log works");
ok($l->debug("Perl Dancer test message with log_path setting 2/5"), "debug works");
ok($l->warning("Perl Dancer test message with log_path setting  3/5"), "warning works");
ok($l->error("Perl Dancer test message with log_path setting 4/5"), "error works");
ok($l->info("Perl Dancer test message with log_path setting 5/5"), "info works");

ok(-f path($dir2,'foo.bar'), "Log file foo.bar exists");


$l->{fh}->close;
