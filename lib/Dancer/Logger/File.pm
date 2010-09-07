package Dancer::Logger::File;
use strict;
use warnings;
use base 'Dancer::Logger::Abstract';

use File::Spec;
use Dancer::Config 'setting';
use Dancer::FileUtils 'path';

my $logfile;

sub logdir {
    my $appdir = setting('appdir');
    my $logroot = $appdir || File::Spec->tmpdir();
    return path($logroot, 'logs');
}

sub init {
    my $logdir = logdir();

    if (!-d $logdir) {
        if (not mkdir $logdir) {
            warn "log directory $logdir doesn't exist, unable to create";
            undef $logfile;
            return;
        }
    }

    $logfile = setting('environment');
    $logfile = path($logdir, "$logfile.log");

    my $fh;
    unless (open($fh, '>>', $logfile)) {
        warn "Unable to open $logfile for writing, unable to log";
        undef $logfile;
    }
    close $fh;
}

sub _log {
    my ($self, $level, $message) = @_;
    return unless defined $logfile;

    if (open(my $fh, '>>', $logfile)) {
        print $fh $self->format_message($level => $message);
        close $fh;
    }
}

1;
