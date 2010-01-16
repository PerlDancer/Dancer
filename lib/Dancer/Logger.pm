package Dancer::Logger;
# Factory for logger engines

use strict;
use warnings;

# singleton used for logging messages
my $logger;
sub logger  { $logger }

sub init {
    my ($class, $setting) = @_;
    if ($setting eq 'file') {
        require Dancer::Logger::File;
        $logger = Dancer::Logger::File->new;
    }
    elsif ($setting eq 'syslog') {
        require Dancer::Logger::Syslog;
        $logger = Dancer::Logger::Syslog->new;
    }
    elsif ($setting eq 'log_handler') {
        require Dancer::Logger::LogHandler;
        $logger = Dancer::Logger::LogHandler->new;
    }
    else {
        die "unknown logger '$setting'";
    }
}

sub debug   { $logger->debug($_[1]) }
sub warning { $logger->warning($_[1]) }
sub error   { $logger->error($_[1]) }

1;
