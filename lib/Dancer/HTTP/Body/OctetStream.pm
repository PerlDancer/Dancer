package Dancer::HTTP::Body::OctetStream;
our $AUTHORITY = 'cpan:SUKRIA';
$Dancer::HTTP::Body::OctetStream::VERSION = '1.3300'; # TRIAL
use strict;
use base 'Dancer::HTTP::Body';
use bytes;

use File::Temp 0.14;


sub spin {
    my $self = shift;

    unless ( $self->body ) {
        $self->body( File::Temp->new( DIR => $self->tmpdir ) );
    }

    if ( my $length = length( $self->{buffer} ) ) {
        $self->body->write( substr( $self->{buffer}, 0, $length, '' ), $length );
    }

    if ( $self->length == $self->content_length ) {
        seek( $self->body, 0, 0 );
        $self->state('done');
    }
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dancer::HTTP::Body::OctetStream

=head1 VERSION

version 1.3300

=head1 SYNOPSIS

    use Dancer::HTTP::Body::OctetStream;

=head1 DESCRIPTION

HTTP Body OctetStream Parser.

=head1 NAME

Dancer::HTTP::Body::OctetStream - HTTP Body OctetStream Parser

=head1 METHODS

=over 4

=item spin

=back

=head1 AUTHOR

Christian Hansen, C<ch@ngmedia.com>

=head1 LICENSE

This library is free software . You can redistribute it and/or modify 
it under the same terms as perl itself.

=head1 AUTHOR

Dancer Core Developers

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Alexis Sukrieh.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
