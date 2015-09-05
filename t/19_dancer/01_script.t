use strict;
use warnings;

use Test::More import => ['!pass'];

my @cases = (
    'A',
    'A::B',
    'A::B::C',
    'A::B::C::D',
);

plan skip_all => "File::Temp 0.22 required"
    unless Dancer::ModuleLoader->load( 'File::Temp', '0.22' );

plan tests => 3 + @cases;

use Cwd qw(cwd);
use Dancer;
use Dancer::FileUtils;

my $dir = File::Temp::tempdir(CLEANUP => 1, TMPDIR => 1);
my $cwd = cwd;

chdir $dir;
END {
    chdir $cwd;
}

my $libdir = File::Spec->catdir($cwd,'lib');
$libdir = '"'.$libdir.'"' if $libdir =~ / /; # this is for windows, but works in UNIX systems as well...

my $dancer = File::Spec->catfile( $cwd, 'bin', 'dancer' );
$dancer = '"'.$dancer.'"' if $dancer =~ / /; #same here.

# the same can happen with perl itself, but while nobody complain, keep it quiet.
my $cmd = "$^X -I $libdir $dancer";

chomp( my $version = qx{$cmd -v} );
is($version, "Dancer $Dancer::VERSION", "dancer -v");

my $nothing = qx{$cmd};
like($nothing, qr{Usage: .* dancer .* options}sx, 'dancer (without parameters)');

my $help = qx{$cmd};
like($help, qr{Usage: .* dancer .* options}sx, 'dancer (without parameters)');

foreach my $case (@cases) {
    my $create_here = qx{$cmd -x -a $case 2> err};
    is scalar(Dancer::FileUtils::read_file_content('err')) => '',
      "create $case did not return error";
}
