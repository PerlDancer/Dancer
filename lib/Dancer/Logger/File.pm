package Dancer::Logger::File;
# ABSTRACT: file-based logging engine for Dancer
use strict;
use warnings;
use Carp;
use base 'Dancer::Logger::Abstract';

use File::Temp qw/tempdir/;
use Dancer::Config 'setting';
use Dancer::FileUtils qw(open_file);
use IO::File;

=method logdir

Returns the log directory, decided by "logs" either in "appdir"
setting or in a temp directory. It's also possible to specify a logs
directory with the log_path option.

  set log_path => $dir;

=cut
sub logdir {
    my $altpath = setting('log_path');
    return $altpath if $altpath;

    my $logroot = setting('appdir');

    if ($logroot) {
        if (!-d $logroot && not mkdir $logroot) {
            carp "log directory $logroot doesn't exist, am unable to create it";
            return;
        }
    } else {
        unless($logroot = tempdir(CLEANUP => 1, TMPDIR => 1)) {
            carp "cannot create temp log directory";
            return;
        }
    }

    my $expected_path = Dancer::FileUtils::path_no_verify($logroot, 'logs');
    return $expected_path if (-d $expected_path && -x _ && -w _);

    unless (-w $logroot and -x _) {
        my $perm = (stat $logroot)[2] & 07777;
        chmod($perm | 0700, $logroot);
        unless (-w $logroot and -x _) {
            carp "log directory $logroot isn't writable/executable and can't chmod it";
            return;
        }
    }
    return $expected_path;
}

=method init

This method is called when C<< ->new() >> is called. It initializes the log
directory, creates if it doesn't already exist and opens the designated log
file.

=cut
sub init {
    my $self = shift;
    $self->SUPER::init(@_);

    my $logdir = logdir();
    return unless ($logdir);

    my $logfile = setting('log_file') || setting('environment').".log";

    mkdir($logdir) unless(-d $logdir);
    $logfile = File::Spec->catfile($logdir, $logfile);

    my $fh;
    unless($fh = open_file('>>', $logfile)) {
        carp "unable to create or append to $logfile";
        return;
    }
    $fh->autoflush;
    $self->{logfile} = $logfile;
    $self->{fh} = $fh;
}


=method _log

Writes the log message to the file.

=cut
sub _log {
    my ($self, $level, $message) = @_;
    my $fh = $self->{fh};

    return unless(ref $fh && $fh->opened);

    $fh->print($self->format_message($level => $message))
        or carp "writing to logfile $self->{logfile} failed";
}

1;
__END__

=head1 SYNOPSIS

=head1 DESCRIPTION

This is a file-based logging engine that allows you to save your logs to files
on disk.

=cut

