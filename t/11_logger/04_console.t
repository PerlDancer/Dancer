# this test makes sure the "console" logger send log messages to STDERR

use strict;
use warnings;
use Test::More import => ['!pass'];

use Dancer::ModuleLoader;
use Dancer;

plan skip_all => "Test::Output is needed for this test"
    unless Dancer::ModuleLoader->load('Test::Output');

plan tests => 8;

use_ok 'Dancer::Logger::Console';
my $l = Dancer::Logger::Console->new;

ok(defined($l), "logger is defined");
isa_ok($l, 'Dancer::Logger::Abstract');
isa_ok($l, 'Dancer::Logger::Console');

Test::Output::stderr_like( sub { $l->debug("debug message") }, 
    qr/\[\d+\] debug @.+> debug message in/,
    "debug  output is sent to STDERR");

Test::Output::stderr_like( sub { $l->warning("warning message") }, 
    qr/\[\d+\]  warn @.+> warning message in/,
    "warning log output is sent to STDERR");

Test::Output::stderr_like( sub { $l->error("error message") }, 
    qr/\[\d+\] error @.+> error message in/,
    "error output is sent to STDERR");

Test::Output::stderr_like( sub { $l->info("info message") }, 
    qr/\[\d+\]  info @.+> info message in/,
    "info output is sent to STDERR");
