package Dancer::Logger::Capture::Trap;
# ABSTRACT: a place to store captured Dancer logs
use base 'Dancer::Object';

__PACKAGE__->attributes( "_storage" );

sub init {
    my $self = shift;
    $self->_storage([]) unless $self->_storage;
}

=method store

    $trap->store($level, $message);

Stores a log $message and its $level.

=cut

sub store {
    my($self, $level, $message) = @_;

    push @{$self->_storage}, { level => $level, message => $message };
}


=method read

    my $logs = $trap->read;

Returns the logs stored as an array ref and clears the storage.

For example...

    [{ level => "warning", message => "Danger! Warning! Dancer!" },
     { level => "error",   message => "You fail forever" }
    ];

=cut

sub read {
    my $self = shift;

    my $logs = $self->_storage;
    $self->_storage([]);
    return $logs;
}

1;

__END__

=head1 SYNOPSIS

    my $trap = Dancer::Logger::Capture::Trap->new;
    $trap->store( $level, $message );
    my $logs = $trap->read;

=head1 DESCRIPTION

This is a place to store and retrieve capture Dancer logs used by
L<Dancer::Logger::Capture>.

=cut

