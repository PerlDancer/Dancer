package Dancer::HTTP::Body::XFormsMultipart;

use strict;
use base 'Dancer::HTTP::Body::MultiPart';
use bytes;

use IO::File;
use File::Temp 0.14;

=head1 NAME

Dancer::HTTP::Body::XFormsMultipart - HTTP Body XForms multipart/related submission Parser

=head1 SYNOPSIS

    use Dancer::HTTP::Body::XForms;

=head1 DESCRIPTION

HTTP Body XForms submission Parser. Inherits Dancer::HTTP::Body::MultiPart.

This body type is used to parse XForms submission. In this case, the
XML part that contains the model is indicated by the start attribute
in the content-type. The XML content is stored unparsed on the
parameter XForms:Model.

=head1 METHODS

=over 4

=item init

This function is overridden to detect the start part of the
multipart/related post.

=cut

sub init {
    my $self = shift;
    $self->SUPER::init(@_);
    unless ( $self->content_type =~ /start=\"?\<?([^\"\>;,]+)\>?\"?/ ) {
        my $content_type = $self->content_type;
        Carp::croak( "Invalid boundary in content_type: '$content_type'" );
    }
    
    $self->{start} = $1;

    return $self;
}

=item start

Defines the start part of the multipart/related body.

=cut

sub start {
    return shift->{start};
}

=item handler

This function is overridden to differ the start part, which should be
set as the XForms:Model param if its content type is application/xml.

=cut

sub handler {
    my ( $self, $part ) = @_;

    my $contentid = $part->{headers}{'Content-ID'};
    $contentid =~ s/^.*[\<\"]//;
    $contentid =~ s/[\>\"].*$//;
    
    if ( $contentid eq $self->start ) {
        $part->{name} = 'XForms:Model';
        if ($part->{done}) {
            $self->body($part->{data});
        }
    }
    elsif ( defined $contentid ) {
        $part->{name}     = $contentid;
        $part->{filename} = $contentid;
    }

    return $self->SUPER::handler($part);
}

=back

=head1 AUTHOR

Daniel Ruoso C<daniel@ruoso.com>

=head1 LICENSE

This library is free software . You can redistribute it and/or modify 
it under the same terms as perl itself.

=cut

1;
