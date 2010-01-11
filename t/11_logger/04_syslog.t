use Test::More;
use strict;
use warnings;
use Dancer::ModuleLoader;

plan skip_all => "Sys::Syslog needed for this test"
    unless Dancer::ModuleLoader->load('Sys::Syslog');
plan tests => 9;

use_ok 'Dancer::Logger::Syslog';

my $l = Dancer::Logger::Syslog->new;

ok defined($l), 'Dancer::Logger::Syslog object';
isa_ok $l, 'Dancer::Logger::Syslog';
can_ok $l, qw(init _log debug warning error);

my $format = Dancer::Logger::Syslog::_format('debug', 'test');
like $format, qr/\(debug\) test in/, 
    "format looks good";

SKIP: { 
    eval { $l->_log(debug => "dummy test") };
    skip "Need a SysLog connection to run last tests", 4 
        if $@ =~ /no connection to syslog available/;

    ok($l->_log(debug => "Perl Dancer test message 1/4"), "_log works");
    ok($l->debug("Perl Dancer test message 2/4"), "debug works");
    ok($l->warning("Perl Dancer test message 3/4"), "warning works");
    ok($l->error("Perl Dancer test message 4/4"), "error works");
};
