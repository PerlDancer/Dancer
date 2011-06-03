use Test::More tests => 3;
use Dancer::Script;

my $script = Dancer::Script->new(appname => 'Hello', path => '.', check_version => '1');
isa_ok( $script, 'Dancer::Script', );
can_ok( $script, 'parse_opts', 'validate_app_name', );
can_ok( $script, '_set_application_path', '_set_script_path', '_set_lib_path', );

