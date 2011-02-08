package Dancer::Helpers;

# helpers are function intended to be called from a route handler. They can
# alter the response of the route handler by changing the head or the body of
# the response.

use strict;
use warnings;
use Carp qw(carp);

use Dancer::Response;
use Dancer::Config 'setting';
use Dancer::Session;
use Dancer::SharedData;
use Dancer::Template;

sub send_file {
    my ($path) = @_;

    my $request = Dancer::Request->new_for_request( 'GET' => $path );
    Dancer::SharedData->request($request);

    my $resp = Dancer::Renderer::get_file_response();
    return $resp if $resp;

    Dancer::Error->new(
        code    => 404,
        message => "No such file: `$path'"
    )->render();
}

sub template {
    my ($view, $tokens, $options) = @_;

    my $content;

    if ($view) {
        $content = Dancer::Template->engine->apply_renderer($view, $tokens);
        if (! defined $content) {
            return Dancer::Error->new(
                code    => 404,
                message => "Page not found",
            )->render();
        }
    } else {
        $options ||= {};
        $content = delete $options->{content};
    }

    my $full_content = Dancer::Template->engine->apply_layout($content, $tokens, $options);
    defined $full_content
      and return $full_content;

    Dancer::Error->new(
        code    => 404,
        message => "Page not found",
    )->render();
}

# DEPRECATED
sub render_with_layout {
    my ($content, $tokens, $options) = @_;
    carp "'render_with_layout' is DEPRECATED, use the 'engine' keyword "
       . "to get the template engine, and use 'apply_layout' on the result";

    my $full_content = Dancer::Template->engine->apply_layout($content, $tokens, $options);

    if (! defined $full_content) {
        return Dancer::Error->new(
            code    => 404,
            message => "Page not found",
        )->render();
    }
    return $full_content;
}

sub error {
    my ($class, $content, $status) = @_;
    $status ||= 500;
    Dancer::Error->new(code => $status, message => $content)->render();
}

sub redirect {
    my ($destination, $status) = @_;
    if ($destination =~ m!^(\w://)?/!) {

        # no absolute uri here, build one, RFC 2616 forces us to do so
        my $request = Dancer::SharedData->request;
        $destination = $request->uri_for($destination, {}, 1);
    }
    my $response = Dancer::SharedData->response;;
    $response->status($status || 302);
    $response->headers('Location' => $destination);
    return;
}

#
# set_cookie name => value,
#     expires => time() + 3600, domain => '.foo.com'
sub set_cookie {
    my ($name, $value, %options) = @_;
    Dancer::Cookies->cookies->{$name} = Dancer::Cookie->new(
        name  => $name,
        value => $value,
        %options
    );
}

1;
