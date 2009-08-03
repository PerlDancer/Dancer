package Dancer::Logger::File;
use strict;
use warnings;
use base 'Dancer::Logger';

use Dancer::Config 'setting';
use Dancer::FileUtils 'path';

my $levels = {
    debug => 1,
    warning => 2,
    error => 3,
};

my $logfile;
sub init {
    my $logdir = path(setting('appdir'), 'logs');
    if (! -d $logdir) {
        mkdir $logdir 
            or die "log directory $logdir doen't exist, unable to create";
    }

    $logfile = setting('environment') || 'default';    
    $logfile = path($logdir, "$logfile.log");

    unless (open(LOGFILE, '>>', $logfile)) {
        warn "Unable to open $logfile for writing, unable to log";
        undef $logfile;
    }
}

sub debug   { _log('debug', $_[1]) }
sub warning { _log('warning', $_[1]) }
sub error   { _log('error', $_[1]) }

sub _log {
    my ($msg_level, $msg_content) = @_;
    return unless defined $logfile;

    my $log_level = setting('log') || 'debug';

    if (($levels->{$log_level} <= $levels->{$msg_level}) && 
        open(LOGFILE, '>>', $logfile)) {
        my ($package, $file, $line) = caller(3);
        my $time = localtime;
        chomp $msg_content;
        print LOGFILE "$time [$$] ($msg_level) $msg_content in $file l. $line\n";
        close LOGFILE;
    }
}

'Dancer::Logger::File';
