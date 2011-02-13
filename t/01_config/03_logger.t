use Test::More tests => 15, import => ['!pass'];

use Dancer ':syntax';
use Dancer::FileUtils;

use File::Temp qw/tempdir/;
use File::Spec qw/catfile/;

my $dir = tempdir(CLEANUP => 1);
set appdir => $dir;

eval { logger 'foobar'};
like($@, qr/unknown logger/, 'invalid logger detected');

ok(logger('file'), 'file-based logger correctly set');

my $message = 'this is a test log message';

ok(debug($message), "debug sent");
ok(warning($message), "warning sent");
ok(error($message), "error sent");

my $logdir = Dancer::FileUtils::path_no_verify(setting('appdir'), 'logs');
ok((-d $logdir), "log directory exists");

my $logfile = Dancer::FileUtils::d_catfile($logdir, "development.log");
ok((-r $logfile), "logfile exists");

open LOGFILE, '<', $logfile;
my @content = <LOGFILE>;
close LOGFILE;

ok(grep(/debug \@.*$message/, @content), 'debug message found');
ok(grep(/warn \@.*$message/, @content), 'warning message found');
ok(grep(/error \@.*$message/, @content), 'error message found');

unlink $logfile;

set environment => 'test';
logger 'file';

$logfile = Dancer::FileUtils::d_catfile($logdir, "test.log");
ok((-r $logfile), "environment logfile exists");

open LOGFILE, '<', $logfile;
@content = <LOGFILE>;
close LOGFILE;

ok(set(log => 'warning'), 'log level set to warning');

ok(!debug($message), 'debug message is dropped');
ok(warning($message), 'warning message is logged');
ok(error($message), 'error message is logged');

Dancer::Logger::logger->{fh}->close;
unlink $logfile;
File::Temp::cleanup();
