package Dancer::HTTP::Body;
our $AUTHORITY = 'cpan:SUKRIA';
$Dancer::HTTP::Body::VERSION = '1.3300'; # TRIAL
use strict;

use Carp       qw[ ];

our $TYPES = {
    'application/octet-stream'          => 'Dancer::HTTP::Body::OctetStream',
    'application/x-www-form-urlencoded' => 'Dancer::HTTP::Body::UrlEncoded',
    'multipart/form-data'               => 'Dancer::HTTP::Body::MultiPart',
    'multipart/related'                 => 'Dancer::HTTP::Body::XFormsMultipart',
    'application/xml'                   => 'Dancer::HTTP::Body::XForms',
    'application/json'                  => 'Dancer::HTTP::Body::OctetStream',
};

require Dancer::HTTP::Body::OctetStream;
require Dancer::HTTP::Body::UrlEncoded;
require Dancer::HTTP::Body::MultiPart;
require Dancer::HTTP::Body::XFormsMultipart;
require Dancer::HTTP::Body::XForms;

use HTTP::Headers;
use HTTP::Message;


sub new {
    my ( $class, $content_type, $content_length ) = @_;

    unless ( @_ >= 2 ) {
        Carp::croak( $class, '->new( $content_type, [ $content_length ] )' );
    }

    my $type;
    my $earliest_index;
    foreach my $supported ( keys %{$TYPES} ) {
        my $index = index( lc($content_type), $supported );
        if ($index >= 0 && (!defined $earliest_index || $index < $earliest_index)) {
            $type           = $supported;
            $earliest_index = $index;
        }
    }

    my $body = $TYPES->{ $type || 'application/octet-stream' };

    my $self = {
        cleanup        => 0,
        buffer         => '',
        chunk_buffer   => '',
        body           => undef,
        chunked        => !defined $content_length,
        content_length => defined $content_length ? $content_length : -1,
        content_type   => $content_type,
        length         => 0,
        param          => {},
        param_order    => [],
        state          => 'buffering',
        upload         => {},
        part_data      => {},
        tmpdir         => File::Spec->tmpdir(),
    };

    bless( $self, $body );

    return $self->init;
}

sub DESTROY {
    my $self = shift;
    
    if ( $self->{cleanup} ) {
        my @temps = ();
        for my $upload ( values %{ $self->{upload} } ) {
            push @temps, map { $_->{tempname} || () }
                ( ref $upload eq 'ARRAY' ? @{$upload} : $upload );
        }
        
        unlink map { $_ } grep { -e $_ } @temps;
    }
}


sub add {
    my $self = shift;
    
    if ( $self->{chunked} ) {
        $self->{chunk_buffer} .= $_[0];
        
        while ( $self->{chunk_buffer} =~ m/^([\da-fA-F]+).*\x0D\x0A/ ) {
            my $chunk_len = hex($1);
            
            if ( $chunk_len == 0 ) {
                # Strip chunk len
                $self->{chunk_buffer} =~ s/^([\da-fA-F]+).*\x0D\x0A//;
                
                # End of data, there may be trailing headers
                if (  my ($headers) = $self->{chunk_buffer} =~ m/(.*)\x0D\x0A/s ) {
                    if ( my $message = HTTP::Message->parse( $headers ) ) {
                        $self->{trailing_headers} = $message->headers;
                    }
                }
                
                $self->{chunk_buffer} = '';
                
                # Set content_length equal to the amount of data we read,
                # so the spin methods can finish up.
                $self->{content_length} = $self->{length};
            }
            else {
                # Make sure we have the whole chunk in the buffer (+CRLF)
                if ( length( $self->{chunk_buffer} ) >= $chunk_len ) {
                    # Strip chunk len
                    $self->{chunk_buffer} =~ s/^([\da-fA-F]+).*\x0D\x0A//;
                    
                    # Pull chunk data out of chunk buffer into real buffer
                    $self->{buffer} .= substr $self->{chunk_buffer}, 0, $chunk_len, '';
                
                    # Strip remaining CRLF
                    $self->{chunk_buffer} =~ s/^\x0D\x0A//;
                
                    $self->{length} += $chunk_len;
                }
                else {
                    # Not enough data for this chunk, wait for more calls to add()
                    return;
                }
            }
            
            unless ( $self->{state} eq 'done' ) {
                $self->spin;
            }
        }
        
        return;
    }
    
    my $cl = $self->content_length;

    if ( defined $_[0] ) {
        $self->{length} += length( $_[0] );
        
        # Don't allow buffer data to exceed content-length
        if ( $self->{length} > $cl ) {
            $_[0] = substr $_[0], 0, $cl - $self->{length};
            $self->{length} = $cl;
        }
        
        $self->{buffer} .= $_[0];
    }

    unless ( $self->state eq 'done' ) {
        $self->spin;
    }

    return ( $self->length - $cl );
}


sub body {
    my $self = shift;
    $self->{body} = shift if @_;
    return $self->{body};
}


sub chunked {
    return shift->{chunked};
}


sub cleanup {
    my $self = shift;
    $self->{cleanup} = shift if @_;
    return $self->{cleanup};
}


sub content_length {
    return shift->{content_length};
}


sub content_type {
    return shift->{content_type};
}


sub init {
    return $_[0];
}


sub length {
    return shift->{length};
}


sub trailing_headers {
    return shift->{trailing_headers};
}


sub spin {
    Carp::croak('Define abstract method spin() in implementation');
}


sub state {
    my $self = shift;
    $self->{state} = shift if @_;
    return $self->{state};
}


sub param {
    my $self = shift;

    if ( @_ == 2 ) {

        my ( $name, $value ) = @_;

        if ( exists $self->{param}->{$name} ) {
            for ( $self->{param}->{$name} ) {
                $_ = [$_] unless ref($_) eq "ARRAY";
                push( @$_, $value );
            }
        }
        else {
            $self->{param}->{$name} = $value;
        }

        push @{$self->{param_order}}, $name;
    }

    return $self->{param};
}


sub upload {
    my $self = shift;

    if ( @_ == 2 ) {

        my ( $name, $upload ) = @_;

        if ( exists $self->{upload}->{$name} ) {
            for ( $self->{upload}->{$name} ) {
                $_ = [$_] unless ref($_) eq "ARRAY";
                push( @$_, $upload );
            }
        }
        else {
            $self->{upload}->{$name} = $upload;
        }
    }

    return $self->{upload};
}


sub part_data {
    my $self = shift;

    if ( @_ == 2 ) {

        my ( $name, $data ) = @_;

        if ( exists $self->{part_data}->{$name} ) {
            for ( $self->{part_data}->{$name} ) {
                $_ = [$_] unless ref($_) eq "ARRAY";
                push( @$_, $data );
            }
        }
        else {
            $self->{part_data}->{$name} = $data;
        }
    }

    return $self->{part_data};
}


sub tmpdir {
    my $self = shift;
    $self->{tmpdir} = shift if @_;
    return $self->{tmpdir};
}


sub param_order {
    return shift->{param_order};
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dancer::HTTP::Body

=head1 VERSION

version 1.3300

=head1 SYNOPSIS

    use Dancer::HTTP::Body;
    
    sub handler : method {
        my ( $class, $r ) = @_;

        my $content_type   = $r->headers_in->get('Content-Type');
        my $content_length = $r->headers_in->get('Content-Length');
        
        my $body   = Dancer::HTTP::Body->new( $content_type, $content_length );
        my $length = $content_length;

        while ( $length ) {

            $r->read( my $buffer, ( $length < 8192 ) ? $length : 8192 );

            $length -= length($buffer);
            
            $body->add($buffer);
        }
        
        my $uploads     = $body->upload;     # hashref
        my $params      = $body->param;      # hashref
        my $param_order = $body->param_order # arrayref
        my $body        = $body->body;       # IO::Handle
    }

=head1 DESCRIPTION

Dancer::HTTP::Body parses chunks of HTTP POST data and supports
application/octet-stream, application/json, application/x-www-form-urlencoded,
and multipart/form-data.

Chunked bodies are supported by not passing a length value to new().

It is currently used by L<Catalyst> to parse POST bodies.

=head1 NAME

Dancer::HTTP::Body - HTTP Body Parser

=head1 NOTES

When parsing multipart bodies, temporary files are created to store any
uploaded files.  You must delete these temporary files yourself after
processing them, or set $body->cleanup(1) to automatically delete them
at DESTROY-time.

=head1 METHODS

=over 4 

=item new 

Constructor. Takes content type and content length as parameters,
returns a L<Dancer::HTTP::Body> object.

=item add

Add string to internal buffer. Will call spin unless done. returns
length before adding self.

=item body

accessor for the body.

=item chunked

Returns 1 if the request is chunked.

=item cleanup

Set to 1 to enable automatic deletion of temporary files at DESTROY-time.

=item content_length

Returns the content-length for the body data if known.
Returns -1 if the request is chunked.

=item content_type

Returns the content-type of the body data.

=item init

return self.

=item length

Returns the total length of data we expect to read if known.
In the case of a chunked request, returns the amount of data
read so far.

=item trailing_headers

If a chunked request body had trailing headers, trailing_headers will
return an HTTP::Headers object populated with those headers.

=item spin

Abstract method to spin the io handle.

=item state

Returns the current state of the parser.

=item param

Get/set body parameters.

=item upload

Get/set file uploads.

=item part_data

Just like 'param' but gives you a hash of the full data associated with the
part in a multipart type POST/PUT.  Example:

    {
      data => "test",
      done => 1,
      headers => {
        "Content-Disposition" => "form-data; name=\"arg2\"",
        "Content-Type" => "text/plain"
      },
      name => "arg2",
      size => 4
    }

=item tmpdir 

Specify a different path for temporary files.  Defaults to the system temporary path.

=item param_order

Returns the array ref of the param keys in the order how they appeared on the body

=back

=head1 SUPPORT

Since its original creation this module has been taken over by the Catalyst
development team. If you want to contribute patches, these will be your
primary contact points:

IRC:

    Join #catalyst-dev on irc.perl.org.

Mailing Lists:

    http://lists.scsys.co.uk/cgi-bin/mailman/listinfo/catalyst-dev

=head1 AUTHOR

Christian Hansen, C<chansen@cpan.org>

Sebastian Riedel, C<sri@cpan.org>

Andy Grundman, C<andy@hybridized.org>

=head1 CONTRIBUTORS

Simon Elliott C<cpan@papercreatures.com>

Kent Fredric <kentnl@cpan.org>

Christian Walde

Torsten Raudssus <torsten@raudssus.de>

=head1 LICENSE

This library is free software. You can redistribute it and/or modify 
it under the same terms as perl itself.

=head1 AUTHOR

Dancer Core Developers

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Alexis Sukrieh.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
