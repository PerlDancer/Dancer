package Dancer::Session::Simple;
our $AUTHORITY = 'cpan:SUKRIA';
#ABSTRACT: in-memory session backend for Dancer
$Dancer::Session::Simple::VERSION = '1.3202';
use strict;
use warnings;
use base 'Dancer::Session::Abstract';

my %sessions;

# create a new session and return the newborn object
# representing that session
sub create {
    my ($class) = @_;

    my $self = Dancer::Session::Simple->new;
    $self->flush;
    return $self;
}

# Return the session object corresponding to the given id
sub retrieve {
    my ($class, $id) = @_;

    return $sessions{$id};
}


sub destroy {
    my ($self) = @_;
    undef $sessions{$self->id};
}

sub flush {
    my $self = shift;
    $sessions{$self->id} = $self;
    return $self;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dancer::Session::Simple - in-memory session backend for Dancer

=head1 VERSION

version 1.3202

=head1 DESCRIPTION

This module implements a very simple session backend, holding all session data
in memory.  This means that sessions are volatile, and no longer exist when the
process exits.  This module is likely to be most useful for testing purposes.

=head1 CONFIGURATION

The setting B<session> should be set to C<Simple> in order to use this session
engine in a Dancer application.

=head1 AUTHOR

This module has been written by David Precious, see the AUTHORS file for
details.

=head1 SEE ALSO

See L<Dancer::Session> for details about session usage in route handlers.

=head1 COPYRIGHT

This module is copyright (c) 2010 David Precious <davidp@preshweb.co.uk>

=head1 LICENSE

This module is free software and is released under the same terms as Perl
itself.

=head1 AUTHOR

Dancer Core Developers

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Alexis Sukrieh.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
