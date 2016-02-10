package Dancer::HTTP::Body::XForms;

use strict;
use base 'Dancer::HTTP::Body';
use bytes;

use File::Temp 0.14;

=head1 NAME

Dancer::HTTP::Body::XForms - HTTP Body XForms Parser

=head1 SYNOPSIS

    use Dancer::HTTP::Body::XForms;

=head1 DESCRIPTION

HTTP Body XForms Parser. This module parses single part XForms
submissions, which are identifiable by the content-type
application/xml. The XML is stored unparsed on the parameter
XForms:Model.

=head1 METHODS

=over 4

=item spin

This method is overwrited to set the param XForms:Model with
the buffer content.

=cut

sub spin {
    my $self = shift;

    return unless $self->length == $self->content_length;

    $self->body($self->{buffer});
    $self->param( 'XForms:Model', $self->{buffer} );
    $self->{buffer} = '';
    $self->{state}  = 'done';

    return $self->SUPER::init();
}

=back

=head1 AUTHOR

Daniel Ruoso, C<daniel@ruoso.com>

=head1 LICENSE

This library is free software . You can redistribute it and/or modify 
it under the same terms as perl itself.

=cut

1;
