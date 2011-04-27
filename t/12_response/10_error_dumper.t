use strict;
use warnings;

use Test::More;
use Dancer::Error;
use Dancer::ModuleLoader;

plan skip_all => 'Clone is required for this test'
    unless Dancer::ModuleLoader->load('Clone');

plan tests => 3;

my $error_obj = Dancer::Error->new(
    code => '404',
    pass => 'secret',
);

isa_ok( $error_obj, 'Dancer::Error' );

my $censored = $error_obj->dumper;

like(
    $censored,
    qr/\QNote: Values of 1 sensitive-looking keys hidden\E/,
    'Data was censored in the output',
);

is(
    $error_obj->{'pass'},
    'secret',
    'Original data was not overwritten',
);

1;

