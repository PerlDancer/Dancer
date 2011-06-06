use strict;
use warnings;

use Cwd;
use Dancer::FileUtils;

use Test::More tests => 6, import => ['!pass'];
use File::Temp 'tempdir';
use File::Spec;

my %cases = (
    'A'    => [ 'A',   'lib/A.pm'   ],
    'A::B' => [ 'A-B', 'lib/A/B.pm' ],
);

my $dir = tempdir(CLEANUP => 1, TMPDIR => 1);
my $cwd = cwd;

chdir $dir;
END {
    chdir $cwd;
}

my $cmd = "$^X -I"                                    .
          File::Spec->catdir(  $cwd, 'blib', 'lib', ) . ' ' .
          File::Spec->catfile( $cwd, 'script', 'dancer' );

foreach my $case ( keys %cases ) {
    my ( $casedir, $casefile ) = @{ $cases{$case} };

    # create the app
    qx{$cmd -a $case};

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
