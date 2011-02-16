use strict;
use warnings;
use Test::More import => ['!pass'];

use Dancer::Config;
use File::Temp qw/tempdir/;

plan skip_all => "YAML needed to run this tests"
    unless Dancer::ModuleLoader->load('YAML');

plan tests => 2;

eval {
    Dancer::Config::load_settings_from_yaml('foo');
};

like $@, qr/Unable to parse the configuration file/;

my $dir = tempdir(CLEANUP => 1, TMPDIR => 1);

my $config_file = File::Spec->catfile($dir, 'settings.yml');

open my $fh, '>', $config_file;
print $fh '---foo\n';
close $fh;

eval {
    Dancer::Config::load_settings_from_yaml($config_file);
};

like $@, qr/Unable to parse the configuration file/;

File::Temp::cleanup();
