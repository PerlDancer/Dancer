use strict;
use warnings;
use Test::More tests => 4;

BEGIN { use_ok 'Dancer::ModuleLoader' }

ok( Dancer::ModuleLoader->load("File::Spec"), "File::Spec is loaded" );
ok( File::Spec->rel2abs('.'), "File::Spec is imported" );
ok( !Dancer::ModuleLoader->load("Non::Existent::Module"), "fake module is not loaded" );
