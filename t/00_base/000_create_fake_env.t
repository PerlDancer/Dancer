use strict;
use warnings;

use File::Spec;
use File::Path;
use File::Basename;
use Test::More tests => 4 * 2, import => ['!pass'];

foreach my $dir ( qw/ public logs views lib / ) {
	my $new_dir = File::Spec->catdir(
		dirname($0), $dir
	);

	my $newer_dir = File::Spec->catdir(
		't', 'lib', $dir
	);

	ok(
		-d $new_dir or mkpath($new_dir),
		"Created $new_dir",
	);
	
	ok(
		-d $newer_dir or mkpath($newer_dir),
		"Created $newer_dir",
	);
}