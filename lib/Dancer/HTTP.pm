package Dancer::HTTP;

use strict;
use warnings;
use base 'Exporter';
use vars '@EXPORT_OK';

@EXPORT_OK = 'status';

my $HTTP_CODES = {
    200 => 'OK',
    
    # redirections
    301 => 'Moved Permanently',
    302 => 'Found',
    # 303 => '303 See Other', # only on HTTP 1.1
    304 => 'Not Modified',
    # 305 => '305 Use Proxy', # only on HTTP 1.1
    306 => 'Switch Proxy',
    # 307 => '307 Temporary Redirect', # on HTTP 1.1

    404 => 'Not found',
    500 => 'Internal Server Error',
    503 => 'Forbidden',
};

# aliases
for my $code ( keys %$HTTP_CODES ) {
	my $alias = lc join '_', split /\W/, $HTTP_CODES->{$code};
    my $status_line = $code . ' ' . $HTTP_CODES->{$code};
	$HTTP_CODES->{$alias} = $status_line;
    $HTTP_CODES->{$code} = $status_line;
}

# own aliases
$HTTP_CODES->{error} = $HTTP_CODES->{internal_server_error};

sub status { 
    my $name = shift;
    die "unknown HTTP status code: $name" unless exists $HTTP_CODES->{$name};
    return "HTTP/1.0 " . $HTTP_CODES->{$name} . "\r\n";
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
