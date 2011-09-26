use strict;
use warnings;

use Test::More tests => 10;
use Dancer::FileUtils 'normalize_path';

my %paths = (
    'one/../two'           => 'two',
    '/one/../two'          => '/two',
    '//one/../two'         => '//two',
    '/one/../two/../three' => '/three',
    'one/two/three/../'    => 'one/two/',
    '/one/two/three/../'   => '/one/two/',
    'one/./two/./three/'   => 'one/two/three/',
    'a/../b'               => 'b',
    'a/b/../../c'          => 'c',
    'a/b/c/../../../d'     => 'd',
);

foreach my $path ( keys %paths ) {
    my $result = $paths{$path};

    is(
        normalize_path($path),
        $result,
        "Normalized $path => $result",
    );
}
