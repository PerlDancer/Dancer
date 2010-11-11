use strict;
use warnings;

use File::Spec;
use File::Path;
use File::Basename;
use Test::More tests => 4 * 3, import => ['!pass'];

my @dirs = map {
    $_,
    File::Spec->catdir( dirname($0), $_ ),
    File::Spec->catdir( 't', 'lib', $_ ),
} qw/ public logs views lib /;

foreach my $dir (@dirs) {
    ok(
        ( -d $dir or mkpath($dir) ),
        "Created $dir",
    );
}
