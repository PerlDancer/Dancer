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
temp directory.

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

