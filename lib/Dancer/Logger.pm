package Dancer::Logger;
# ABSTRACT: common interface for loggin in Dancer

=head1 DESCRIPTION

This module is the wrapper that provides support for different 
logger engines.

=cut

use strict;
use warnings;
use Data::Dumper;
use Dancer::Engine;

my $_logger;

sub init {
    my ($class, $name, $config) = @_;
    $_logger = Dancer::Engine->build(logger => $name, $config);
}

=method logger

Returns the current active logger engine.

=cut
sub logger {$_logger}

=method core

Writes to the logger in the C<core> level.

=cut
sub core    { defined($_logger) and $_logger->core(    _serialize(@_) ) }

=method debug

Writes to the logger in the C<debug> level.

=cut
sub debug   { defined($_logger) and $_logger->debug(   _serialize(@_) ) }

=method warning

Writes to the logger in the C<warning> level.

=cut
sub warning { defined($_logger) and $_logger->warning( _serialize(@_) ) }

=method error

Writes to the logger in the C<error> level.

=cut
sub error   { defined($_logger) and $_logger->error(   _serialize(@_) ) }

# private

sub _serialize {
    my @vars = @_;

    return join q{}, map {
        ref $_                      ?
            Data::Dumper->new([$_])
                        ->Terse(1)
                        ->Purity(1)
                        ->Indent(0)
                        ->Dump()    :
            $_
    } @vars;
}

1;

__END__

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

=head2 Auto-serializing

The loggers allow auto-serializing of all inputs:

    debug( 'User credentials: ', \%creds );

Will provide you with an output in a single log message of the string and the
reference dump.

=cut


