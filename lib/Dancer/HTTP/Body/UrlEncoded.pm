package Dancer::HTTP::Body::UrlEncoded;

use strict;
use base 'Dancer::HTTP::Body';
use bytes;

our $DECODE = qr/%([0-9a-fA-F]{2})/;

our %hex_chr;

for my $num ( 0 .. 255 ) {
    my $h = sprintf "%02X", $num;
    $hex_chr{ lc $h } = $hex_chr{ uc $h } = chr $num;
}

=head1 NAME

Dancer::HTTP::Body::UrlEncoded - HTTP Body UrlEncoded Parser

=head1 SYNOPSIS

    use Dancer::HTTP::Body::UrlEncoded;

=head1 DESCRIPTION

HTTP Body UrlEncoded Parser.

=head1 METHODS

=over 4

=item spin

=cut

sub spin {
    my $self = shift;

    # Still Copy buffer to body temp file, just like other parsers - some users
    # will expect to be able to get at the raw body with the body method still 
    # (not unreasonably) 
    unless ($self->body) {
        $self->body(File::Temp->new(DIR => $self->tmpdir));
    }

    if (my $length = length($self->{buffer})) {
        $self->body->write(substr($self->{buffer}, 0, $length),
            $length);
    }

    return unless $self->length == $self->content_length;
    
    # I tested parsing this using APR::Request, but perl is faster
    # Pure-Perl    2560/s
    # APR::Request 2305/s
    
    # Note: s/// appears faster than tr///


    $self->{buffer} =~ s/\+/ /g;

    for my $pair ( split( /[&;](?:\s+)?/, $self->{buffer} ) ) {

        my ( $name, $value ) = split( /=/, $pair , 2 );

        next unless defined $name;
        next unless defined $value;
        
        $name  =~ s/$DECODE/$hex_chr{$1}/gs;
        $value =~ s/$DECODE/$hex_chr{$1}/gs;

        $self->param( $name, $value );
    }

    $self->{buffer} = '';
    $self->{state}  = 'done';
}

=back

=head1 AUTHORS

Christian Hansen, C<ch@ngmedia.com>

Andy Grundman, C<andy@hybridized.org>

=head1 LICENSE

This library is free software . You can redistribute it and/or modify 
it under the same terms as perl itself.

=cut

1;
