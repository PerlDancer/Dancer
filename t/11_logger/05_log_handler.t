use Test::More;
use strict;
use warnings;
use Dancer::ModuleLoader;

plan skip_all => "Log::Handler needed for this test"
  unless Dancer::ModuleLoader->load('Log::Handler');
plan tests => 10;

use_ok 'Dancer::Logger::LogHandler';

my $l = Dancer::Logger::LogHandler->new();

ok defined($l), 'Dancer::Logger::LogHandler object';
isa_ok $l, 'Dancer::Logger::LogHandler';
can_ok $l, qw(init _log debug warning error);

my $format = Dancer::Logger::LogHandler::_format('test');
like $format, qr/test in/, "format looks good";

ok($l->_log(debug => "dummy test"));
ok($l->_log(debug => "Perl Dancer test message 1/4"), "_log works");
ok($l->debug("Perl Dancer test message 2/4"),   "debug works");
ok($l->warning("Perl Dancer test message 3/4"), "warning works");
ok($l->error("Perl Dancer test message 4/4"),   "error works");
