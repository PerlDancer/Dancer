use Test::More import => ['!pass'];
use File::Spec;
use File::Temp;

use Dancer ':syntax';
use Dancer::FileUtils qw/read_file_content path_or_empty/;

use lib File::Spec->catdir( 't', 'lib' );
use TestUtils;

use strict;
use warnings;

plan tests => 3;


my $tmp = File::Temp->new();
write_file($tmp, "one$/two");

my $content = read_file_content($tmp);
ok $content = "one$/two";

my @content = read_file_content($tmp);
ok $content[0] eq "one$/" && $content[1] eq 'two';

# returns UNDEF on non-existant path
my $path = 'bla/blah';
if (! -e $path) {
    is(
        path_or_empty($path),
        '',
        'path_or_empty on non-existent path',
    );
}
