package Dancer::HTTP;

use strict;
use warnings;
use base 'Exporter';
use vars '@EXPORT_OK';

@EXPORT_OK = 'status';

my $HTTP_CODES = {
    200 => '200 OK',
    404 => '404 Not found',
    500 => '500 Internal Server Error',
    503 => '503 Forbidden',
};

# aliases
$HTTP_CODES->{ok} = $HTTP_CODES->{200};
$HTTP_CODES->{not_found} = $HTTP_CODES->{404};
$HTTP_CODES->{error} = $HTTP_CODES->{500};
$HTTP_CODES->{forbidden} = $HTTP_CODES->{503};

sub status { 
    my $name = shift;
    return undef unless exists $HTTP_CODES->{lc($name)};
    return "HTTP/1.0 " . $HTTP_CODES->{lc($name)} . "\r\n";
}

'Dancer::HTTP';
__END__
=pod

=head1 NAME

Dancer::HTTP

=head1 DESCRIPTION

Helper for rendering HTTP status codes for Dancer

=head1 HTTP CODES 

The following codes/aliases are understood by the any satus() call made from a
Dancer script.

=head2 200

returns 200 OK, alias : 'ok'

=head2 404

returns 404 Not Found, alias : 'not_found'

=head2 500

returns 500 Internal Server Error, alias: 'error'

=head2 503

returns 503 Forbidden, alias 'forbidden'

=head1 AUTHOR

This module has been written by Alexis Sukrieh <sukria@cpan.org>

=head1 SOURCE CODE

The source code for this module is hosted on GitHub
L<http://github.com/sukria/Dancer>

=head1 LICENSE

This module is free software and is published under the same
terms as Perl itself.

=cut
