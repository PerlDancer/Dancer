package Dancer::Logger::LogHandler;
use strict;
use warnings;
use base 'Dancer::Logger::Abstract';

use Dancer::Config 'setting';

my $_logger;

sub _config {
    my $conf = setting('log_handler');
    $conf ? return $conf : return {
        screen => {
            log_to   => "STDERR",
            maxlevel => "debug",
            minlevel => "warning"
        }
    };
}

sub init {
    my $self = shift;
    die "Log::Handler is needed for the Syslog Logger Engine"
      unless Dancer::ModuleLoader->load('Log::Handler');
    my $settings = _config();
    $_logger = Log::Handler->new();
    map { $_logger->add($_ => $settings->{$_}) } keys %$settings;
}

sub _log {
    my ($self, $level, $message) = @_;
    $_logger->$level(_format($message));
}

sub _format {
    my $message = shift;
    my ($package, $file, $line) = caller(4);
    $package ||= '-';
    $file ||= '-';
    $line ||= '-';

    chomp $message;
    return "$message in $file l. $line\n";
}

1;

__END__

=head1 NAME Dancer::Log::LogHandler - Log::Handler wrapper for Dancer

=head1 DESCRIPTION

This class is an interface between Dancer's logging engine abstraction layer and the L<Log::Handler> module.

In order to use this engine, set the following setting as follow:

  logger: 'log_handler'

This can be done in your config.yml file or directly in your app code with the
B<set> keyword

The default configuration of this module is to write log message on STDERR. You can change this behavior by adding a similar configuration:

  log_handler:
    file:
      filename: debug.log
      maxlevel: debug
      minlevel: warning
    screen:
      log_to: "STDERR"
      maxlevel: debug
      minlevel: warning

=head1 SEE ALSO

L<Dancer>, L<Log::Handler>

=head1 AUTHOR

This module has been written by Franck Cuny

=head1 LICENSE

This module is free software and is released under the same terms as Perl
itself.

=cut
