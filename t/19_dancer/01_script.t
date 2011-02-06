use strict;
use warnings;

use Test::More import => ['!pass'];

my @cases = (
    'A',
    'A::B',
    'A::B::C',
    'A::B::C::D',
);

plan tests => 3 + @cases;

use Cwd        qw(cwd);
use File::Temp qw(tempdir);

use Dancer;

sub slurp {
    my $file = shift;
    open my $fh, '<', $file or die;
    local $/ = undef;
    <$fh>;
}

my $dir = tempdir( CLEANUP => 1 );
my $cwd = cwd;

chdir $dir;
END {
    chdir $cwd;
}

my $cmd = "$^X -I "                                       .
          File::Spec->catdir(  $cwd, 'blib',   'lib'    ) . '  ' .
          File::Spec->catfile( $cwd, 'script', 'dancer' );
chomp( my $version = qx{$cmd -v} );
is($version, "Dancer $Dancer::VERSION", "dancer -v");

my $nothing = qx{$cmd};
like($nothing, qr{Usage: .* dancer .* options}sx, 'dancer (without parameters)');

my $help = qx{$cmd};
like($help, qr{Usage: .* dancer .* options}sx, 'dancer (without parameters)');

foreach my $case (@cases) {
    my $create_here = qx{$cmd -a $case 2> err};
    my $err = slurp('err');
    is($err, '', "create $case did not return error");
}

