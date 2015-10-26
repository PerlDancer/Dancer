use strict;
use warnings;
use Test::More import => ['!pass'];

use Dancer::Config;

plan skip_all => "YAML needed to run this tests"
    unless Dancer::ModuleLoader->load('YAML');

plan skip_all => "File::Temp 0.22 required"
    unless Dancer::ModuleLoader->load( 'File::Temp', '0.22' );

plan tests => 2;

eval {
    Dancer::Config::load_settings_from_yaml('foo');
};

like $@, qr/Unable to parse the configuration file/, 'non-existent yaml file';

my $dir = File::Temp::tempdir(CLEANUP => 1, TMPDIR => 1);

my $config_file = File::Spec->catfile($dir, 'settings.yml');

open my $fh, '>', $config_file;
print $fh '---"foo';
close $fh;

eval {
    Dancer::Config::load_settings_from_yaml($config_file);
};

like $@, qr/Unable to parse the configuration file/, 'invalid yaml file';

File::Temp::cleanup();
