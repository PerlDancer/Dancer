use strict;
use warnings;
use Test::More import => ['!pass'];

plan skip_all => "YAML needed to run this tests"
    unless Dancer::ModuleLoader->load('YAML');
plan skip_all => "File::Temp 0.22 required"
    unless Dancer::ModuleLoader->load( 'File::Temp', '0.22' );
plan tests => 12;

use Dancer ':syntax';
use File::Spec;
use lib File::Spec->catdir( 't', 'lib' );
use TestUtils;

my $dir = File::Temp::tempdir(CLEANUP => 1, TMPDIR => 1);
set appdir => $dir;
my $envdir = File::Spec->catdir($dir, 'environments');
mkdir $envdir;

my $conffile = Dancer::Config->conffile;

# create the conffile
my $conf = <<"END";
port: 4500
startup_info: 0
99_bottles: "can't touch this"
99_more_bottles:
  this_method: "can be called"
alist:
  - first_element:
    foo: bar
  - second_element:
    baz: quux
    this: rocks
charset: "UTF8"
logger: file
auth:
  username: ovid
  password: hahahah
strict_config: 1
END
write_file($conffile => $conf);
ok(Dancer::Config->load, 'Config load works with a conffile');
ok(Dancer::Config->load, '... and it should be safe to call more than once');

can_ok config, 'port';
is config->port, '4500', 'basic methods should work with strict configs';
is config->auth->username, 'ovid', '... and as should chained methods';
is config->{port}, '4500',
  '... but we should still be able to reach into the config';

ok !config->can('99_bottles'), 'We do not try to build invalid method names';
is config->{'99_bottles'}, "can't touch this",
  "... but we do not discard them, either";
is config->{'99_more_bottles'}->this_method, 'can be called',
  "... but they can still chain methods";

is config->alist->[1]->baz, 'quux', '... and we still can call list methods';

eval { config->auth->pass };
my $error = $@;

like $error, qr/Can't locate config attribute "pass"/,
    'Calling non-existent config methods should die';

like $error, qr/Available attributes: password, username/,
    '... and tell us which attributes are available';

Dancer::Logger::logger->{fh}->close;
unlink Dancer::Config->environment_file;
unlink $conffile;
File::Temp::cleanup();
