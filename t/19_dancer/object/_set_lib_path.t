use Test::More tests => 1;
use Dancer::Script;

my $script = Dancer::Script->new(appname => 'Hello::World', path => '.', check_version => '1');

my @lib_path = split('::', $script->{appname});
my ($lib_file, $lib_path) = (pop @lib_path) . ".pm";
ok( $script->{lib_file}, $lib_file, "_set_lib_path sets correctly ->{lib_file} and ->{lib_path}");
ok( $script->{lib_path}, $lib_path, "_set_lib_path sets correctly ->{lib_file} and ->{lib_path}");
