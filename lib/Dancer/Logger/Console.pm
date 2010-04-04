package Dancer::Logger::Console;
use strict;
use warnings;
use base 'Dancer::Logger::Abstract';

use Dancer::Config 'setting';

# TODO should be refactored in Dancer::Logger::Abstract
sub _format {
    my ($level, $message) = @_;
    my ($package, $file, $line) = caller(3);
    $package ||= '-';
    $file    ||= '-';
    $line    ||= '-';

    my $time = localtime;
    chomp $message;
    return "$time [$$] ($level) $message in $file l. $line\n";
}

sub _log {
    my ($self, $level, $message) = @_;
    print STDERR _format($level => $message);
}

1;
