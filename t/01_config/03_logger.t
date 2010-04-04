use Test::More tests => 15, import => ['!pass'];

use Dancer::Config 'setting';
use Dancer ':syntax';

use File::Temp qw/tempdir/;
my $dir = tempdir(CLEANUP => 1);
set appdir => $dir;

eval { logger 'foobar'};
like($@, qr/unknown logger/, 'invalid logger detected');

ok(logger('file'), 'file-based logger correctly set');

my $message = 'this is a test log message';

ok(debug($message), "debug sent");
ok(warning($message), "warning sent");
ok(error($message), "error sent");

my $logdir = path(setting('appdir'), 'logs');
ok((-d $logdir), "log directory exists");

my $logfile = path($logdir, "development.log");
ok((-r $logfile), "logfile exists");

open LOGFILE, '<', $logfile;
my @content = <LOGFILE>;
close LOGFILE;

ok(grep(/\(debug\) $message/, @content), 'debug message found');
ok(grep(/\(warning\) $message/, @content), 'warning message found');
ok(grep(/\(error\) $message/, @content), 'error message found');

unlink $logfile;

set environment => 'test';
logger 'file';

$logfile = path($logdir, "test.log");
ok((-r $logfile), "environment logfile exists");

open LOGFILE, '<', $logfile;
@content = <LOGFILE>;
close LOGFILE;


ok(set(log => 'warning'), 'log level set to warning');

ok(!debug($message), 'debug message is dropped');
ok(warning($message), 'warning message is logged');
ok(error($message), 'error message is logged');

unlink $logfile;
