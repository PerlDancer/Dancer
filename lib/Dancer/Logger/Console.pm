package Dancer::Logger::Console;
use strict;
use warnings;
use base 'Dancer::Logger::Abstract';

use Dancer::Config 'setting';

sub _log {
    my ($self, $level, $message) = @_;
    print STDERR $self->format_message($level => $message);
}

1;
