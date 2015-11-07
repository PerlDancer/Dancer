package Dancer::Logger::Note;
our $AUTHORITY = 'cpan:SUKRIA';
#ABSTRACT: Test::More note() logging engine for Dancer
$Dancer::Logger::Note::VERSION = '1.3202';
use strict;
use warnings;
use base 'Dancer::Logger::Abstract';

sub init {
    my $self = shift;
    $self->SUPER::init(@_);
    require Test::More;
}

sub _log {
    my ($self, $level, $message) = @_;

    Test::More::note(
        $self->format_message( $level => $message )
    );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dancer::Logger::Note - Test::More note() logging engine for Dancer

=head1 VERSION

version 1.3202

=head1 SYNOPSIS

=head1 DESCRIPTION

This logging engine uses L<Test::More>'s note() to output as TAP comments.

This is very useful in case you're writing a test and want to have logging
messages as part of your TAP.

"Like C<diag()>, except the message will not be seen when the test is run in a
harness. It will only be visible in the verbose TAP stream." -- Test::More.

=head1 METHODS

=head2 init

This method is called when C<< ->new() >> is called. It just loads Test::More
lazily.

=head2 _log

Use Test::More's note() to output the log message.

=head1 AUTHOR

Dancer Core Developers

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Alexis Sukrieh.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
