package Test::Dancer;
# test helpers for Dancer apps

use strict;
use warnings;
use Test::More;

use Dancer::Request;
use Dancer::SharedData;
use Dancer::Renderer;

use base 'Exporter';
use vars '@EXPORT';

@EXPORT = qw(
    route_exists
    response_status_is
    response_content_like
);

sub route_exists {
    my ($args, $message) = @_;
    my ($method, $path) = @$args;
    my $req = Dancer::Request->new_for_request($method => $path);

    ok(Dancer::Route->find($path, $method, $req), $message);
}

sub response_status_is {
    my ($req, $status, $message) = @_;
    my ($method, $path) = @$req;
    my $request = Dancer::Request->new_for_request($method => $path);
    Dancer::SharedData->request($request);
    my $response = Dancer::Renderer::get_action_response();
    
    is $response->{status}, $status, $message;
}

sub response_content_like {
    my ($req, $matcher, $message) = @_;
    my ($method, $path) = @$req;
    my $request = Dancer::Request->new_for_request($method => $path);
    Dancer::SharedData->request($request);
    my $response = Dancer::Renderer::get_action_response();
    
    like $response->{content}, $matcher, $message;
}

1;
__END__
=pod

=head1 NAME

Test::Dancer - Test helpers to test a Dancer application

=head1 SYNOPSYS

    use strict;
    use warnings;
    use Test::More tests => 2;

    use Test::Dancer;
    use MyWebApp;

    response_status_is [GET => '/'], 200, "GET / is found";
    response_content_like [GET => '/'], qr/hello, world/, "content looks good for /";


=head1 DESCRIPTION

This module provides test heplers for testing Dancer apps.

=head1 METHODS

=head2 route_exists([$method, $path], $message)

Asserts that the given request matches a route handler in Dancer's
registry.

    route_exists [GET => '/'], "GET / is handled";

=head2 response_status_is([$method, $path], $status, $message)

Asserts that Dancer's response for the given request has a status equal to the
one given.

    response_status_is [GET => '/'], 200, "response for GET / is 200";

=head2 response_content_like([$method, $path], $regexp, $message)

Asserts that the response content for the given request matches the regexp
given.

    response_content_like [GET => '/'], qr/Hello, World/, 
        "response content looks good for GET /";


=head1 LICENSE

This module is free software and is distributed under the same terms as Perl
itself.

=head1 AUTHOR

This module has been written by Alexis Sukrieh <sukria@sukria.net>

=head1 SEE ALSO

L<Test::More>

=cut
