package Dancer::HTTP;
our $AUTHORITY = 'cpan:SUKRIA';
#ABSTRACT: helper for rendering HTTP status codes for Dancer
$Dancer::HTTP::VERSION = '1.3202';
use strict;
use warnings;
use base 'Exporter';
use vars '@EXPORT_OK';

my %HTTP_CODES = (

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
);

my %STATUS_TO_CODE = map { my $s = $_; $s =~ s/\W/_/g; lc $s } 
                         'error' => 500,        # our alias to 500
                         reverse %HTTP_CODES;


# always return a numeric status code
# if alias, return the corresponding code
sub status {
    my (undef, $name) = @_;

    return $name if $name =~ /^\d+$/;

    $name =~ s/\W/_/g;
    return $STATUS_TO_CODE{lc $name};
}

sub codes {
    my %copy = %HTTP_CODES;
    return \%copy;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dancer::HTTP - helper for rendering HTTP status codes for Dancer

=head1 VERSION

version 1.3202

=head1 DESCRIPTION

Helper for rendering HTTP status codes for Dancer

=head1 METHODS

=head2 status( $status )

Returns the numerical status of C<$status>.

    # all three are equivalent, and will return '405'

    $x = Dancer::HTTP->status( 405 );
    $x = Dancer::HTTP->status( 'Method Not Allowed' );
    $x = Dancer::HTTP->status( 'method_not_allowed' );

=head2 codes

Returns a hashref of all HTTP status known to C<Dancer>. The
keys are the numerical statuses and the values their string equivalents.

    print Dancer::HTTP->codes->{404}; # prints 'File Not Found'

=head1 HTTP CODES 

The following codes/aliases are understood by any status() call made
from a Dancer script. The aliases can be used as-is (e.g., I<Moved
Permanently>), or as lower-case string with all non-alphanumerical 
characters changed to underscores (e.g., I<moved_permanently>).

    get '/user/:user' => sub {
        my $user = find_user( param('user') );

        unless ( $user ) {
            status 404;

            # or could be
            status 'not_found';

            # or even
            status 'Not Found';
        }

        ...
    };

=head2 Processed Codes

=over

=item 200 - OK

=item 201 - Created

=item 202 - Accepted

=item 204 - No Content

=item 205 - Reset Content

=item 206 - Partial Content

=back

=head2 Redirections

=over

=item 301 - Moved Permanently

=item 302 - Found

=item 304 - Not Modified

=item 306 - Switch Proxy

=back

=head2 Problem with request

=over

=item 400 - Bad Request

=item 401 - Unauthorized

=item 402 - Payment Required

=item 403 - Forbidden

=item 404 - Not Found

=item 405 - Method Not Allowed

=item 406 - Not Acceptable

=item 407 - Proxy Authentication Required

=item 408 - Request Timeout

=item 409 - Conflict

=item 410 - Gone

=item 411 - Length Required

=item 412 - Precondition Failed

=item 413 - Request Entity Too Large

=item 414 - Request-URI Too Long

=item 415 - Unsupported Media Type

=item 416 - Requested Range Not Satisfiable

=item 417 - Expectation Failed

=back

=head2 Problem with server

=over

=item 500 - Internal Server Error

Also aliases as 'error'.

=item 501 - Not Implemented

=item 502 - Bad Gateway

=item 503 - Service Unavailable

=item 504 - Gateway Timeout

=item 505 - HTTP Version Not Supported

=back

=head1 AUTHOR

This module has been written by Alexis Sukrieh <sukria@cpan.org>

=head1 SOURCE CODE

The source code for this module is hosted on GitHub
L<https://github.com/PerlDancer/Dancer>

=head1 LICENSE

This module is free software and is published under the same
terms as Perl itself.

=head1 AUTHOR

Dancer Core Developers

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Alexis Sukrieh.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
