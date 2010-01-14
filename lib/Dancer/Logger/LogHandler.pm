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
