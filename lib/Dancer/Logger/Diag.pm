package Dancer::Logger::Diag;
# ABSTRACT: Test::More diag() logging engine for Dancer

=head1 SYNOPSIS

  my $diag = Dancer::Logger::Diag->new();
  $diag->_log( $level, $message);

=head1 DESCRIPTION

This logging engine uses L<Test::More>'s diag() to output as TAP comments.

This is very useful in case you're writing a test and want to have logging
messages as part of your TAP.

=cut

use strict;
use warnings;
use base 'Dancer::Logger::Abstract';


=method init

This method is called when C<< ->new() >> is called. It just loads
Test::More lazily.

=cut

sub init {
    my $self = shift;
    $self->SUPER::init(@_);
    require Test::More;
}

=method _log

Use Test::More's diag() to output the log message.

=cut

sub _log {
    my ($self, $level, $message) = @_;

    Test::More::diag(
        $self->format_message( $level => $message )
    );
}

1;

