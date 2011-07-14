package Dancer::Logger::Abstract;

use strict;
use warnings;
use Carp;
use base 'Dancer::Engine';

use Dancer::SharedData;
use Dancer::Timer;
use Dancer::Config 'setting';
use POSIX qw/strftime/;

# This is the only method to implement by logger engines.
# It receives the following arguments:
# $msg_level, $msg_content, it gets called only if the configuration allows
# a message of the given level to be logged.
sub _log { confess "_log not implemented" }

my $levels = {

    # levels < 0 are for core only
    core => -10,

    # levels > 0 are for end-users only
    debug   => 1,
    warn    => 2,
    warning => 2,
    error   => 3,
};

my $log_formats = {
    simple  => '[%P] %L @%D> %i%m in %f l. %l',
};

sub _log_format {
    my $config = setting('logger_format');

    if ( !$config ) {
        return $log_formats->{simple};
    }

    exists $log_formats->{$config}
      ? return $log_formats->{$config}
      : return $config;
}

sub _should {
    my ($self, $msg_level) = @_;
    my $conf_level = setting('log') || 'debug';

    if (!exists $levels->{$conf_level}) {
        setting('log' => 'debug');
        $conf_level = 'debug';
    }

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
    
    my $r     = Dancer::SharedData->request;
    my @stack = caller(3);

    my $block_handler = sub {
        my ( $block, $type ) = @_;
        if ( $type eq 't' ) {
            return "[" . strftime( $block, localtime ) . "]";
        }
        elsif ( $type eq 'h' ) {
            return scalar $r->header($block) || '-';
        }
        else {
            Carp::carp("{$block}$type not supported");
            return "-";
        }
    };

    my $chars_mapping = {
        h => sub {
            defined $r
              ? $r->env->{'HTTP_X_REAL_IP'} || $r->env->{'REMOTE_ADDR'}
              : '-';
        },
        t => sub { Encode::decode(setting('charset'),
                                  POSIX::strftime( "%d/%b/%Y %H:%M:%S", localtime )) },
        T => sub { POSIX::strftime( "%Y-%m-%d %H:%M:%S", localtime  ) },
        P => sub { $$ },
        L => sub { $level },
        D => sub {
            my $time = Dancer::SharedData->timer->tick;
            return $time;
        },
        m => sub { $message },
        f => sub { $stack[1] || '-' },
        l => sub { $stack[2] || '-' },
        i => sub {
            defined $r ? "[hit #" . $r->id . "]" : "";
        },
    };

    my $char_mapping = sub {
        my $char = shift;

        my $cb = $chars_mapping->{$char};
        unless ($cb) {
            Carp::carp "\%$char not supported.";
            return "-";
        }
        $cb->($char);
    };

    my $fmt = $self->_log_format();

    $fmt =~ s{
        (?:
            \%\{(.+?)\}([a-z])|
            \%([a-zA-Z])
        )
    }{ $1 ? $block_handler->($1, $2) : $char_mapping->($3) }egx;

    return $fmt."\n";
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

In your configuration file:

    # default
    logger_format: simple
    # [1234] debug @0.12> [hit #123]message from your log in File.pm line 12

    # custom
    logger_format: %m %{%H:%M}t [%{accept_type}h]
    # message from your log [11:59] [text/html]

=head1 DESCRIPTION

This is an abstract logging engine that provides loggers with basic
functionality and some sanity checking.

=head1 CONFIGURATION

=head2 logger_format

This is a format string (or a preset name) to specify the log format.

The possible values are:

=over 4

=item %h

host emitting the request

=item %t

date (formatted like %d/%b/%Y %H:%M:%S)

=item %P

PID

=item %L

log level

=item %D

timer

=item %m

message

=item %f

file name that emit the message

=item %l

line from the file

=item %i

request ID

=item %{$fmt}t

timer formatted with a valid time format

=item %{header}h

header value

=back

There is two preset possible:

=over 4

=item simple

will format the message like: [%P] %L @%D> %m in %f l. %l

=item with_id

will format the message like: [%P] %L @%D> [hit #%i] %m in %f l. %l

=back

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

