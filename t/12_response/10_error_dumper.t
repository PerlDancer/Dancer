use strict;
use warnings;

use Test::More;
use Dancer::Error;
use Dancer::ModuleLoader;

plan tests => 5;

my $error_obj = Dancer::Error->new(
    code => '404',
    pass => 'secret',
    deep => {
        pass => 'secret'
    },
);

isa_ok( $error_obj, 'Dancer::Error' );

my $censored = $error_obj->dumper;

like(
    $censored,
    qr/\QNote: Values of 2 sensitive-looking keys hidden\E/,
    'Data was censored in the output',
);

is(
    $error_obj->{'pass'},
    'secret',
    'Original data was not overwritten',
);

is(
    $error_obj->{'deep'}{'pass'},
    'secret',
    'Censoring of complex data structures works fine',
);

my %recursive;
$recursive{foo}{bar}{baz}  = 1;
$recursive{foo}{bar}{oops} = $recursive{foo};

$censored = Dancer::Error::_censor( \%recursive );

pass "recursive censored hash";

1;

