use strict;
use warnings;
use Test::More import => ['!pass'];

use Dancer ':syntax';
use Dancer::Config;

plan skip_all => "YAML or YAML::XS needed to run these tests"
    unless Dancer::ModuleLoader->load('YAML::XS')
        or Dancer::ModuleLoader->load('YAML');

plan skip_all => "File::Temp 0.22 required"
    unless Dancer::ModuleLoader->load( 'File::Temp', '0.22' );


for my $module (qw(YAML::XS YAML)) {
    SKIP: {
        if (!Dancer::ModuleLoader->load($module)) {
            skip "$module not available", 2;
        }

        my $mversion = $module->VERSION;
        diag "Testing YAML parsing with $module version $mversion";

        eval {
            Dancer::Config::load_settings_from_yaml('foo', $module);
        };

        like $@, qr/Unable to parse the configuration file/,
            "non-existent YAML file reported correctly, using $module";

        my $dir = File::Temp::tempdir(CLEANUP => 1, TMPDIR => 1);

        my $config_file = File::Spec->catfile($dir, 'settings.yml');

        open my $fh, '>', $config_file;
        print $fh '><(((o>'; # fishy-looking YAML
        close $fh;

        eval {
            Dancer::Config::load_settings_from_yaml($config_file, $module);
        };

        like $@, qr/Unable to parse the configuration file/,
            "invalid YAML file reported correctly, using $module";

        File::Temp::cleanup();
    }

}

done_testing();

