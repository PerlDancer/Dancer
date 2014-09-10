use strict;
use warnings;

use Cwd;
use Dancer::FileUtils;
use Dancer::ModuleLoader;

use Test::More import => ['!pass'];
use File::Spec;

plan skip_all => "File::Temp 0.22 required"
    unless Dancer::ModuleLoader->load( 'File::Temp', '0.22' );

plan tests => 6;

my %cases = (
    'A'    => [ 'A',   'lib/A.pm'   ],
    'A::B' => [ 'A-B', 'lib/A/B.pm' ],
);

my $dir = File::Temp::tempdir(CLEANUP => 1, TMPDIR => 1);
my $cwd = cwd;

chdir $dir;

my $libdir = File::Spec->catdir($cwd, 'blib', 'lib');
$libdir = '"'.$libdir.'"' if $libdir =~ / /;

my $dancer = File::Spec->catdir($cwd, 'bin', 'dancer');
$dancer = '"'.$dancer.'"' if $dancer =~ / /;

my $cmd = "$^X -I $libdir $dancer";

foreach my $case ( keys %cases ) {
    my ( $casedir, $casefile ) = @{ $cases{$case} };

    # create the app
    qx{$cmd -x -a $case};

    # check for directory
    my $exists = -d $casedir;
    ok( $exists, "Created directory for $case" );
    if ($exists ) {
        chdir $casedir;

        $exists = -e $casefile && -f _;
        ok( $exists, "Created file for $case" );

        if ( $exists ) {
            my $makefile = 'Makefile.PL';
            my $content = Dancer::FileUtils::read_file_content($makefile);

            like(
                $content,
                qr/VERSION_FROM \s+ => \s+ '\Q$casefile\E', /x,
                'Created correct VERSION_FROM',
            );
        }

        chdir $dir;
    }
}

chdir $cwd;
