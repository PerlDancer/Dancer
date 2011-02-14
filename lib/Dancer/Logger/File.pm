package Dancer::Logger::File;
use strict;
use warnings;
use Carp;
use base 'Dancer::Logger::Abstract';

use File::Temp qw/tempdir/;
use Dancer::Config 'setting';
use Dancer::FileUtils qw(open_file);
use IO::File;

sub logdir {
    my $altpath = setting('log_path');
    return $altpath if($altpath);
    my $logroot = setting('appdir');
    unless($logroot) {
        $logroot = Dancer::FileUtils::d_catdir(tempdir()); # don't do CLEANUP => 1 here...
        if (!$logroot || ( !-d $logroot && not mkdir $logroot )) {
            carp "log directory $logroot doesn't exist, am unable to create it";
            return;
        }
    }
    if (!-w $logroot or !-x $logroot) {
        my $perm = (stat $logroot)[2] & 07777;
        chmod($perm | 0700, $logroot);
        if (!-w $logroot or !-x $logroot) {
            carp "log directory $logroot isn't writable/executable and can't chmod it";
            return;
        }
    }
    return Dancer::FileUtils::path_no_verify($logroot, 'logs');
}

sub init {
    my ($self) = @_;
    my $logdir = logdir();

    if (!$logdir) {
        return;
    }

    my $logfile = setting('environment');
    $logfile = Dancer::FileUtils::path_no_verify($logdir, "$logfile.log");

    my $fh = open_file('>>', $logfile) or carp "unable to create or append to $logfile";

    $fh->autoflush;
    $self->{logfile} = $logfile;
    $self->{fh} = $fh;
}

sub _log {
    my ($self, $level, $message) = @_;
    my $fh = $self->{fh};

    return unless(ref $fh && $fh->opened);

    $fh->print($self->format_message($level => $message))
        or carp "writing to logfile $self->{logfile} failed";
}

1;

__END__

=head1 NAME

Dancer::Logger::File - file-based logging engine for Dancer

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

Returns the log directory, decided by "logs" either in "appdir" setting or in a
temp directory. It's also possible to specify a logs directory with the log_path option.

  setting log_path => $dir;

=head2 _log

Writes the log message to the file.

=head1 AUTHOR

Alexis Sukrieh

=head1 LICENSE AND COPYRIGHT

Copyright 2009-2010 Alexis Sukrieh.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

