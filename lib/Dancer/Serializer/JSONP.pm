package Dancer::Serializer::JSONP;
our $AUTHORITY = 'cpan:SUKRIA';
$Dancer::Serializer::JSONP::VERSION = '1.3202';
# ABSTRACT: serializer for handling JSONP data

use strict;
use warnings;
use Dancer::SharedData;
use parent 'Dancer::Serializer::JSON';

sub serialize {
    my $self = shift;
	
	my $callback = Dancer::SharedData->request->params('query')->{callback};
	
	my $json = $self->SUPER::serialize(@_);
	
	return $callback . '(' . $json . ');';
}

sub content_type {'application/javascript'}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dancer::Serializer::JSONP - serializer for handling JSONP data

=head1 VERSION

version 1.3202

=head1 SYNOPSIS

=head1 DESCRIPTION

This class is a subclass of L<Dancer::Serializer::JSON> with support for JSONP.

In order to use this engine, use the template setting:

    serializer: JSONP

This can be done in your config.yml file or directly in your app code with the
B<set> keyword. This serializer will B<not> be used when the serializer is set
to B<mutable>.

All configuration options mentioned in L<Dancer::Serializer::JSON> apply here,
too.

=head1 METHODS

=head2 serialize

Serialize a data structure to a JSON structure with surrounding javascript
callback method. The name of the callback method is obtained from the request
parameter I<callback>.

=head2 deserialize

See L<Dancer::Serializer::JSON#deserialize>.

=head2 content_type

Return 'application/javascript'

=head1 SEE ALSO

L<Dancer::Plugin::CORS> is a modern alternative to JSONP, but with limited
browser support. Today, JSONP can be a serious fallback solution when CORS is
not supported by a browser.

=head1 AUTHOR

David Zurborg, C<< <zurborg at cpan.org> >>

=head1 AUTHOR

Dancer Core Developers

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Alexis Sukrieh.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
