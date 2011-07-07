package Dancer::Session::Simple;

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

=head1 NAME

Dancer::Session::Simple - in-memory session backend for Dancer

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

=cut
