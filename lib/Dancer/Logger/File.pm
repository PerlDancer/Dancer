package Dancer::Logger::File;
#ABSTRACT: file-based logging engine for Dancer
use strict;
use warnings;
use Carp;
use base 'Dancer::Logger::Abstract';

use Dancer::Config 'setting';
use Dancer::FileUtils qw(open_file);
use IO::File;
use Fcntl qw(:flock SEEK_END);

sub logdir {
    if ( my $altpath = setting('log_path') ) {
        return $altpath;
    }

    my $logroot = setting('appdir');

    if ( $logroot and ! -d $logroot and ! mkdir $logroot ) {
        carp "app directory '$logroot' doesn't exist, am unable to create it";
        return;
    }

    my $expected_path = $logroot                                  ?
                        Dancer::FileUtils::path($logroot, 'logs') :
                        Dancer::FileUtils::path('logs');

    return $expected_path if -d $expected_path && -x _ && -w _;

    unless (-w $logroot and -x _) {
        my $perm = (stat $logroot)[2] & 07777;
        chmod($perm | 0700, $logroot);
        unless (-w $logroot and -x _) {
            carp "app directory '$logroot' isn't writable/executable and can't chmod it";
            return;
        }
    }
    return $expected_path;
}

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

    # looks like older perls don't auto-convert to IO::File
    # and can't autoflush
    # see https://github.com/PerlDancer/Dancer/issues/954
    eval { $fh->autoflush };

    $self->{logfile} = $logfile;
    $self->{fh} = $fh;
}

sub _log {
    my ($self, $level, $message) = @_;
    my $fh = $self->{fh};

    return unless(ref $fh && $fh->opened);

    flock($fh, LOCK_EX)
        or carp "locking logfile $self->{logfile} failed";
    seek($fh, 0, SEEK_END)
        or carp "seeking to logfile $self->{logfile} end failed";
    $fh->print($self->format_message($level => $message))
        or carp "writing to logfile $self->{logfile} failed";
    flock($fh, LOCK_UN)
        or carp "unlocking logfile $self->{logfile} failed";

}

1;

__END__

=head1 SYNOPSIS

=head1 DESCRIPTION

This is a file-based logging engine that allows you to save your logs to files
on disk.

=head1 METHODS

=head2 init

This method is called when C<< ->new() >> is called. It initializes the log
directory, creates if it doesn't already exist and opens the designated log
file.

=head2 logdir

Returns the log directory, decided by "logs" either in "appdir" setting.
It's also possible to specify a logs directory with the log_path option.

  setting log_path => $dir;

=head2 _log

Writes the log message to the file.

