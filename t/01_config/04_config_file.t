use strict;
use warnings;
use Test::More import => ['!pass'];

eval "use YAML";
plan skip_all => "YAML is not installed" if $@;
plan tests => 16;

use Dancer;
use Dancer::Config 'setting'; 
use lib 't';
use TestUtils;

my $conffile = Dancer::Config->conffile;
ok(defined($conffile), 'default conffile is defined');

ok(Dancer::Config->load, 'Config load works without conffile');

# create the conffile
my $conf = '
port: 4500
access_log: 0
logger: file
';
write_file($conffile => $conf);
ok(Dancer::Config->load, 'Config load works with a conffile');
is(setting('environment'), 'development', 
    'setting environment looks good');
is(setting('port'), '4500',
    'setting port looks good');
is(setting('access_log'), 0,
    'setting access_log looks good');
is(setting('logger'), 'file',
    'setting logger looks good');

ok(defined(Dancer::Logger->logger), 'logger is defined');

my $test_env = '
log: debug
access_log: 1
foo_test: 54
';
write_file(Dancer::Config->environment_file, $test_env);
ok(Dancer::Config->load, 'load test environment');
is(setting('log'), 'debug', 'log setting looks good'); 
is(setting('access_log'), '1', 'access_log setting looks good'); 
is(setting('foo_test'), '54', 'random setting set'); 
unlink Dancer::Config->environment_file;

my $prod_env = '
log: "warning"
access_log: 0
foo_prod: 42
';

setting('environment' => 'prod');
write_file(Dancer::Config->environment_file, $prod_env);

ok(Dancer::Config->load, 'load prod environment');
is(setting('log'), 'warning', 'log setting looks good'); 
is(setting('foo_prod'), '42', 'random setting set'); 
is(setting('access_log'), '0', 'access_log setting looks good'); 
unlink Dancer::Config->environment_file;

unlink $conffile;
