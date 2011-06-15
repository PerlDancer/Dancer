package Dancer::Session::Simple;
# ABSTRACT: basic in-memory session engine

=head1 DESCRIPTION

This module implements a very simple session backend, holding all session data
in memory.  This means that sessions are volatile, and no longer exist when the
process exits.  This module is likely to be most useful for testing purposes.

use strict;
use warnings;
use base 'Dancer::Session::Abstract';

use Dancer::ModuleLoader;
use Dancer::Config 'setting';
use Dancer::FileUtils 'path';

=cut

my %sessions;

=method create

Check C<create> documentation on L<Dancer::Session>.

=cut
sub create {
    my ($class) = @_;

    my $self = Dancer::Session::Simple->new;
    $self->flush;
    return $self;
}

=method retrieve

Check C<retrieve> documentation on L<Dancer::Session>.

=cut
sub retrieve {
    my ($class, $id) = @_;

    return $sessions{$id};
}

=method destroy

Check C<destroy> documentation on L<Dancer::Session>.

=cut
sub destroy {
    my ($self) = @_;
    undef $sessions{$self->id};
}

=method flush

Check C<flush> documentation on L<Dancer::Session>.

=cut
sub flush {
    my $self = shift;
    $sessions{$self->id} = $self;
    return $self;
}

1;
__END__


=head1 CONFIGURATION

The setting B<session> should be set to C<Simple> in order to use this session
engine in a Dancer application.

=cut
