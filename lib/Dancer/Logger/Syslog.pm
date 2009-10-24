package Dancer::Logger::Syslog;

use strict;
use warnings;
use File::Basename 'basename';

use base 'Dancer::Logger::Abstract';

sub init {
    my ($self) = @_;
    die "Sys::Syslog is needed for the Syslog Logger Engine"
        unless Dancer::ModuleLoader->load('Sys::Syslog');
    Sys::Syslog->import(qw(:DEFAULT setlogsock)); 

    my $basename = basename($0);
    setlogsock('unix');
    openlog($basename, 'pid', 'USER');
}

sub DESTROY { closelog() }

sub _format {
    my ($level, $message) = @_;
    my ($package, $file, $line) = caller(4);
    $package ||= '-';
    $file ||= '-';
    $line ||= '-';

    my $time = localtime;
    chomp $message;
    return "($level) $message in $file l. $line\n";
}

sub _log {
    my ($self, $level, $message) = @_;
    my $syslog_levels = {
        debug => 'debug',
        warning => 'warning',
        error => 'err',
    };
    $level = $syslog_levels->{$level};
	return syslog($level, _format($level, $message));
}

1;
