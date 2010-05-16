package Dancer::Logger;

# Factory for logger engines

use strict;
use warnings;
use Dancer::Engine;

# singleton used for logging messages
my $logger;
sub logger {$logger}

sub init {
    my ($class, $name, $config) = @_;
    $logger = Dancer::Engine->build(logger => $name, $config);
}

sub core    { defined($logger) and $logger->core($_[1])    }
sub debug   { defined($logger) and $logger->debug($_[1])   }
sub warning { defined($logger) and $logger->warning($_[1]) }
sub error   { defined($logger) and $logger->error($_[1])   }

1;

__END__

=pod

=head1 NAME

Dancer::Logger - common interface for logging in Dancer

=head1 DESCRIPTION

This module is the wrapper that provides support for different 
logger engines.

=head1 USAGE

=head2 Default engine

The setting B<logger> defined which logger engine to use. 
If this setting is not set, logging will not be available in the application
code.

Dancer comes with the logger engine L<Dancer::Logger::File>, 
but more are available on the CPAN

=head2 Configuration

The B<logger> configuration variable tells Dancer which engine to use.

You can change it either in your config.yml file:

    # logging to syslog
    logger: "syslog"

Or in the application code:

    # logging to file 
    set logger => 'file';

=head1 AUTHORS

This module has been written by Alexis Sukrieh. See the AUTHORS file that comes
with this distribution for details.

=head1 LICENSE

This module is free software and is released under the same terms as Perl
itself.

=head1 SEE ALSO

See L<Dancer> for details about the complete framework.

You can also search the CPAN for existing engines in the Dancer::Logger
namespace : L<http://search.cpan.org/search?query=Dancer%3A%3ALogger>.

=cut
1;
