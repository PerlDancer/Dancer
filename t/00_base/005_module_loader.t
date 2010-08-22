use strict;
use warnings;
use Test::More tests => 6;

BEGIN { use_ok 'Dancer::ModuleLoader' }

ok( Dancer::ModuleLoader->load("File::Spec"), "File::Spec is loaded" );
ok( File::Spec->rel2abs('.'), "File::Spec is imported" );
ok( !Dancer::ModuleLoader->load("Non::Existent::Module"), "fake module is not loaded" );

ok( Dancer::ModuleLoader->load("File::Spec", "1.0"), "File::Spec version >= 1.0 is loaded");
ok( !Dancer::ModuleLoader->load("File::Spec", "9999"), "Can't load File::Spec v9999");
