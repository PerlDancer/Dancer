package Dancer::Logger;
our $AUTHORITY = 'cpan:SUKRIA';
#ABSTRACT: common interface for logging in Dancer
$Dancer::Logger::VERSION = '1.3202';
# Factory for logger engines

use strict;
use warnings;
use Data::Dumper;
use Dancer::Engine;

# singleton used for logging messages
my $logger;
sub logger {$logger}

sub init {
    my ($class, $name, $config) = @_;
    $logger = Dancer::Engine->build(logger => $name, $config);
}

sub _serialize {
    my @vars = @_;

    return join q{}, map {
        ref $_ 
            ? Data::Dumper->new([$_])
                          ->Terse(1)
                          ->Purity(1)
                          ->Indent(0)
                          ->Sortkeys(1)
                          ->Dump()
            : (defined($_) ? $_ : 'undef')
    } @vars;
}

sub core    { defined($logger) and $logger->core(    _serialize(@_) ) }
sub debug   { defined($logger) and $logger->debug(   _serialize(@_) ) }
sub info    { defined($logger) and $logger->info(    _serialize(@_) ) }
sub warning { defined($logger) and $logger->warning( _serialize(@_) ) }
sub error   { defined($logger) and $logger->error(   _serialize(@_) ) }

1;

=pod

=encoding UTF-8

=head1 NAME

Dancer::Logger - common interface for logging in Dancer

=head1 VERSION

version 1.3202

=head1 DESCRIPTION

This module is the wrapper that provides support for different 
logger engines.

=head1 USAGE

=head2 Default engine

The setting B<logger> defines which logger engine to use. 
If this setting is not set, logging will not be available in the application
code.

Dancer comes with the logger engines L<Dancer::Logger::File> and
L<Dancer::Logger::Console>, but more are available on the CPAN.

=head2 Configuration

The B<logger> configuration variable tells Dancer which engine to use.

You can change it either in your config.yml file:

    # logging to console
    logger: "console"

Or in the application code:

    # logging to file 
    set logger => 'file';

The log format can also be configured, 
please see L<Dancer::Logger::Abstract/"logger_format"> for details.

=head2 Auto-serializing

The loggers allow auto-serializing of all inputs:

    debug( 'User credentials: ', \%creds );

Will provide you with an output in a single log message of the string and the
reference dump.

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

=head1 AUTHOR

Dancer Core Developers

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Alexis Sukrieh.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__END__

1;
