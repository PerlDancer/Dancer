use strict;
use warnings;

use File::Spec;
use File::Path;
use File::Basename;
use Test::More tests => 4, import => ['!pass'];

foreach my $dir ( qw/ public logs views lib / ) {
    my $new_dir = File::Spec->catdir(
        dirname($0), $dir
    );

    ok(
        ( -d $new_dir or mkpath($new_dir) ),
        "Created $new_dir",
    );
}
