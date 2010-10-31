package Dancer::Logger::Abstract;

use strict;
use warnings;
use Carp;
use base 'Dancer::Engine';

use Dancer::SharedData;
use Dancer::Timer;
use Dancer::Config 'setting';

# This is the only method to implement if logger engines.
# It receives the following arguments:
# $msg_level, $msg_content, it gets called only if the configuration allows
# a message of the given level to be logged.
sub _log { confess "_log not implemented" }

sub _should {
    my ($self, $msg_level) = @_;
    my $conf_level = setting('log') || 'debug';
    my $levels = {

        # levels < 0 are for core only
        core => -10,

        # levels > 0 are for end-users only
        debug   => 1,
        warning => 2,
        error   => 3,
    };
    return $levels->{$conf_level} <= $levels->{$msg_level};
}

sub format_message {
    my ($self, $level, $message) = @_;
    chomp $message;

    if (setting('charset')) {
        $message = Encode::encode(setting('charset'), $message);
    }

    $level = 'warn' if $level eq 'warning';
    $level = sprintf('%5s', $level);

    my ($package, $file, $line) = caller(3);
    $package ||= '-';
    $file    ||= '-';
    $line    ||= '-';

    my $time = Dancer::SharedData->timer->tick;
    my $r    = Dancer::SharedData->request;
    if (defined $r) {
        return
            "[$$] $level \@$time> [hit #"
          . $r->id
          . "] $message in $file l. $line\n";
    }
    else {
        return "[$$] $level \@$time> $message in $file l. $line\n";
    }
}

sub core    { $_[0]->_should('core')    and $_[0]->_log('core',    $_[1]) }
sub debug   { $_[0]->_should('debug')   and $_[0]->_log('debug',   $_[1]) }
sub warning { $_[0]->_should('warning') and $_[0]->_log('warning', $_[1]) }
sub error   { $_[0]->_should('error')   and $_[0]->_log('error',   $_[1]) }

1;

__END__

=head1 NAME

Dancer::Logger::Abstract - Abstract logging engine for Dancer

=head1 SYNOPSIS

=head1 DESCRIPTION

This is an abstract logging engine that provides loggers with basic
functionality and some sanity checking.

=head1 METHODS

=head2 format_message

Provides a common message formatting.

=head2 core

Logs messages as core.

=head2 debug

Logs messages as debug.

=head2 warning

Logs messages as warning.

=head2 error

Logs messages as error.

=head2 _log

A method to override. If your logger does not provide this, it will cause the
application to die.

=head2 _should

Checks a certain level number against a certain level type (core, debug,
warning, error).

=head1 AUTHOR

Alexis Sukrieh

=head1 LICENSE AND COPYRIGHT

Copyright 2009-2010 Alexis Sukrieh.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

