use strict;
use warnings;

use Cwd;
use Dancer;
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
    ok( -d $casedir, "Created directory for $case" );
    if ( -d $casedir ) {
        chdir $casedir;

        ok( -f $casefile, "Created file for $case" );

        if ( -e $casefile ) {
            my $makefile = 'Makefile.PL';
            open my $fh, '<', $makefile or die "Can't open $makefile: $!\n";
            my $content = do { local $/ = undef; <$fh>; };
            close $fh or die "Can't close $makefile: $!\n";

            like(
                $content,
                qr/VERSION_FROM \s+ => \s+ '\Q$casefile\E', /x,
                'Created correct VERSION_FROM',
            );
        }

        chdir $dir;
    }
}
