package Dancer::HTTP::Body::XFormsMultipart;
our $AUTHORITY = 'cpan:SUKRIA';
$Dancer::HTTP::Body::XFormsMultipart::VERSION = '1.3300'; # TRIAL
use strict;
use base 'Dancer::HTTP::Body::MultiPart';
use bytes;

use IO::File;
use File::Temp 0.14;


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


sub start {
    return shift->{start};
}


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


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dancer::HTTP::Body::XFormsMultipart

=head1 VERSION

version 1.3300

=head1 SYNOPSIS

    use Dancer::HTTP::Body::XForms;

=head1 DESCRIPTION

HTTP Body XForms submission Parser. Inherits Dancer::HTTP::Body::MultiPart.

This body type is used to parse XForms submission. In this case, the
XML part that contains the model is indicated by the start attribute
in the content-type. The XML content is stored unparsed on the
parameter XForms:Model.

=head1 NAME

Dancer::HTTP::Body::XFormsMultipart - HTTP Body XForms multipart/related submission Parser

=head1 METHODS

=over 4

=item init

This function is overridden to detect the start part of the
multipart/related post.

=item start

Defines the start part of the multipart/related body.

=item handler

This function is overridden to differ the start part, which should be
set as the XForms:Model param if its content type is application/xml.

=back

=head1 AUTHOR

Daniel Ruoso C<daniel@ruoso.com>

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
