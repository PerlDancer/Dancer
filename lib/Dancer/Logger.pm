package Dancer::Logger;
# virtual class for Dancer logger.

use strict;
use warnings;
use Dancer::Config 'setting';
use Dancer::Logger::File;

# singleton used for logging messages
my $logger;

sub new {
    my ($class) = @_;
    bless {}, $class;
}

sub init {
    if (setting('logger') eq 'file') {
        $logger = Dancer::Logger::File->new;
        $logger->init;
    }
    else {
        die "unknown logger";
    }
}

sub debug       { $logger->debug($_[1]) }
sub warning     { $logger->warning($_[1]) }
sub error       { $logger->error($_[1]) }

'Dancer::Logger';
