use Test::More tests => 1;
use Dancer::Script;

my $script = Dancer::Script->new(appname => 'Hello::World', path => '.', check_version => '1');

is( $script->{dancer_app_dir}, $script->{dancer_script}, "_set_application_path sets correctly ->{dancer_app_dir}");
