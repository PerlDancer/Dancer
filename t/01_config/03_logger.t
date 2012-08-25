use Test::More import => ['!pass'];

use Dancer ':syntax';
use Dancer::FileUtils;

use File::Spec qw/catfile/;

plan skip_all => "File::Temp 0.22 required"
    unless Dancer::ModuleLoader->load( 'File::Temp', '0.22' );

plan tests => 15;

my $dir = File::Temp::tempdir(CLEANUP => 1, TMPDIR => 1);
set appdir => $dir;

eval { set logger => 'foobar' };
like($@, qr/unable to load logger/, 'invalid logger detected');

ok(set(logger => 'file'), 'file-based logger correctly set');

my $message = 'this is a test log message';

ok(debug($message), "debug sent");
ok(warning($message), "warning sent");
ok(error($message), "error sent");

my $logdir = Dancer::FileUtils::path(setting('appdir'), 'logs');
ok((-d $logdir), "log directory exists");

my $dev_logfile = Dancer::FileUtils::path($logdir, "development.log");
ok((-r $dev_logfile), "logfile exists");

open LOGFILE, '<', $dev_logfile;
my @content = <LOGFILE>;
close LOGFILE;

ok(grep(/debug \@.*$message/, @content), 'debug message found');
ok(grep(/warn \@.*$message/, @content), 'warning message found');
ok(grep(/error \@.*$message/, @content), 'error message found');

set environment => 'test';
set logger => 'file';

my $test_logfile = Dancer::FileUtils::path($logdir, "test.log");
ok((-r $test_logfile), "environment logfile exists");

open LOGFILE, '<', $test_logfile;
@content = <LOGFILE>;
close LOGFILE;

ok(set(log => 'warning'), 'log level set to warning');

ok(!debug($message), 'debug message is dropped');
ok(warning($message), 'warning message is logged');
ok(error($message), 'error message is logged');

Dancer::Logger::logger->{fh}->close;
unlink $dev_logfile;
unlink $test_logfile;
File::Temp::cleanup();
