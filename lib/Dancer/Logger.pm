package Dancer::Logger;
# Factory for logger engines

use strict;
use warnings;
use Dancer::Config 'setting';
use Dancer::Logger::File;

# singleton used for logging messages
my $logger;
sub logger  { $logger }

sub init {
    my ($class, $setting) = @_;
    if ($setting eq 'file') {
        $logger = Dancer::Logger::File->new;
    }
    else {
        die "unknown logger '$setting'";
    }
}

sub debug   { $logger->debug($_[1]) }
sub warning { $logger->warning($_[1]) }
sub error   { $logger->error($_[1]) }

1;
