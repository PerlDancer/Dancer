package Dancer::HTTP;

use strict;
use warnings;
use base 'Exporter';
use vars '@EXPORT_OK';

@EXPORT_OK = 'status';

my $HTTP_CODES = {
    # informational
    # 100 => 'Continue', # only on HTTP 1.1
    # 101 => 'Switching Protocols', # only on HTTP 1.1

    # processed codes
    200 => 'OK',
    201 => 'Created',
    202 => 'Accepted',
    # 203 => 'Non-Authoritative Information', # only on HTTP 1.1
    204 => 'No Content',
    205 => 'Reset Content',
    206 => 'Partial Content',
    
    # redirections
    301 => 'Moved Permanently',
    302 => 'Found',
    # 303 => '303 See Other', # only on HTTP 1.1
    304 => 'Not Modified',
    # 305 => '305 Use Proxy', # only on HTTP 1.1
    306 => 'Switch Proxy',
    # 307 => '307 Temporary Redirect', # on HTTP 1.1

    # problems with request
    400 => 'Bad Request',
    401 => 'Unauthorized',
    402 => 'Payment Required',
    403 => 'Forbidden',
    404 => 'Not Found',
    405 => 'Method Not Allowed',
    406 => 'Not Acceptable',
    407 => 'Proxy Authentication Required',
    408 => 'Request Timeout',
    409 => 'Conflict',
    410 => 'Gone',
    411 => 'Length Required',
    412 => 'Precondition Failed',
    413 => 'Request Entity Too Large',
    414 => 'Request-URI Too Long',
    415 => 'Unsupported Media Type',
    416 => 'Requested Range Not Satisfiable',
    417 => 'Expectation Failed',

    # problems with server
    500 => 'Internal Server Error',
    501 => 'Not Implemented',
    502 => 'Bad Gateway',
    503 => 'Service Unavailable',
    504 => 'Gateway Timeout',
    505 => 'HTTP Version Not Supported',
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
