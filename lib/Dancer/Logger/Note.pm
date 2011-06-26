package Dancer::Logger::Note;
# ABSTRACT: Test::More note() logging engine for Dancer
use strict;
use warnings;
use base 'Dancer::Logger::Abstract';

=method init

This method is called when C<< ->new() >> is called. It just loads Test::More
lazily.

=cut
sub init {
    my $self = shift;
    $self->SUPER::init(@_);
    require Test::More;
}

=method _log

Use Test::More's note() to output the log message.

=cut
sub _log {
    my ($self, $level, $message) = @_;

    Test::More::note(
        $self->format_message( $level => $message )
    );
}

1;



__END__

=head1 DESCRIPTION

This logging engine uses L<Test::More>'s note() to output as TAP comments.

This is very useful in case you're writing a test and want to have logging
messages as part of your TAP.

"Like C<diag()>, except the message will not be seen when the test is run in a
harness. It will only be visible in the verbose TAP stream." -- Test::More.

=cut
