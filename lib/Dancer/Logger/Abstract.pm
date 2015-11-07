package Dancer::Logger::Abstract;
our $AUTHORITY = 'cpan:SUKRIA';
#ABSTRACT: Abstract logging engine for Dancer
$Dancer::Logger::Abstract::VERSION = '1.3202';
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
    info    => 2,
    warn    => 3,
    warning => 3,
    error   => 4,
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

    $message = Encode::encode(setting('charset'), $message)
        if setting('charset');

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
            return '-' unless defined $r;
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
              ? $r->env->{'HTTP_X_REAL_IP'} || $r->env->{'REMOTE_ADDR'} || '-'
              : '-';
        },
        t => sub { Encode::decode(setting('charset') || 'utf8',
                                  POSIX::strftime( "%d/%b/%Y %H:%M:%S", localtime )) },
        T => sub { POSIX::strftime( "%Y-%m-%d %H:%M:%S", localtime  ) },
        u => sub { Encode::decode(setting('charset') || 'utf8',
                                  POSIX::strftime( "%d/%b/%Y %H:%M:%S", gmtime )) },
        U => sub { POSIX::strftime( "%Y-%m-%d %H:%M:%S", gmtime  ) },
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

    $fmt =~ s^
        (?:
            \%\{(.+?)\}([a-z])|
            \%([a-zA-Z])
        )
    ^ $1 ? $block_handler->($1, $2) : $char_mapping->($3) ^egx;

    return $fmt."\n";
}

sub core    { $_[0]->_should('core')    and $_[0]->_log('core',    $_[1]) }
sub debug   { $_[0]->_should('debug')   and $_[0]->_log('debug',   $_[1]) }
sub info    { $_[0]->_should('info')    and $_[0]->_log('info',    $_[1]) }
sub warning { $_[0]->_should('warning') and $_[0]->_log('warning', $_[1]) }
sub error   { $_[0]->_should('error')   and $_[0]->_log('error',   $_[1]) }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dancer::Logger::Abstract - Abstract logging engine for Dancer

=head1 VERSION

version 1.3202

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

date (local timezone, formatted like %d/%b/%Y %H:%M:%S)

=item %T

date (local timezone, formatted like %Y-%m-%d %H:%M:%S)

=item %u

date (UTC timezone, formatted like %d/%b/%Y %H:%M:%S)

=item %U

date (UTC timezone, formatted like %Y-%m-%d %H:%M:%S)

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

There is currently a single preset log format:

=over 4

=item simple

will format the message like: [%P] %L @%D> %i%m in %f l. %l

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

=head2 info

Logs messages as info.

=head2 _log

A method to override. If your logger does not provide this, it will cause the
application to die.

=head2 _should

Checks a certain level number against a certain level type (core, debug, info
warning, error).

=head1 AUTHOR

Dancer Core Developers

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Alexis Sukrieh.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
