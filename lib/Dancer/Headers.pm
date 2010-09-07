package Dancer::Headers;
use strict;
use warnings;
use base 'Dancer::Object';

sub init {
    my ($self, %params) = @_;
    $self->{_headers} = {};

    my $headers = $params{headers};

    if (ref($headers) eq 'ARRAY') {
        my $parsed = {};

        for (my $i = 0; $i < scalar(@$headers); $i += 2) {
            my ($key, $value) = ($headers->[$i], $headers->[$i + 1]);
            if (defined $parsed->{$key}) {
                $parsed->{$key} = [$parsed->{$key}];
                push @{$parsed->{$key}}, $value;
            }
            else {
                $parsed->{$key} = $value;
            }
        }
        $self->{_headers} = $parsed;
    }
    elsif (ref($headers) eq 'HTTP::Headers') {
        my @headers = $headers->header_field_names;
        for my $h (@headers) {
            my @values = $headers->header($h);
            $self->{_headers}{$h} = (@values == 1) ? $values[0] : \@values;
        }
    }
    else {
        die "unsupported headers: $headers";
    }

    return $self;
}

sub get {
    my ($self, $header) = @_;
    my $value = $self->{_headers}{$header};

    return unless defined $value;
    return $value unless ref($value);
    return wantarray ? @$value : $value->[0];
}

sub get_all { $_[0]->{_headers} }


1;
__END__

=pod

=head1 NAME 

Dancer::Headers - Wrapper to handle request headers

=head1 SYNOPSYS

    use Dancer::Headers;

    # $headers may be either an ARRAY of key-value pairs, or 
    # an HTTP::Headers object.
    $dh = Dancer::Headers->new(headers => $headers);

    # $dh is now a normalized object, which lets the user do:
    # $dh->get('Some-Header');

=head1 DESCRIPTION

This class implements a wrapper that can provide a common interface to access
headers, no matter what their origin is.

When the Dancer application is ran under Plack, the headers are accessed via
L<Plack::Request>, which returns a L<HTTP::Headers> object. When under the
standalone server (powered by L<HTTP::Server::Simple::PSGI>, the headers are
sent as an array.

Dancer::Headers takes care of normalizing those two kind of data structure into
a singe object.

=head1 METHODS

=head2 get($header)

Returns the value of the given $header. 

ARRAY references are stored for headers with multiple values. When get is called
in a scalar context on such entries, it returns the first value stored, if
called in list context, it returns all the values.

    $headers = Dancer::Headers->new([foo => 1, foo => 2]);
    my $first = $headers->get('foo'); # 1
    my @all   = $headers->get('foo'); # (1, 2)

=head2 get_all()

Returns the whole normalized HASH reference. 

=head1 AUTHORS

This module as been writen by Alexis Sukrieh

=head1 SEE ALSO

L<Dancer>

=cut
