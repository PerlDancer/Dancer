package Dancer::Helpers;

# helpers are function intended to be called from a route handler. They can
# alter the response of the route handler by changing the head or the body of
# the response.

use strict;
use warnings;
use Carp;

use Dancer::Response;
use Dancer::Config 'setting';
use Dancer::Session;
use Dancer::SharedData;
use Dancer::Template;

sub send_file {
    my ($path) = @_;

    my $request = Dancer::Request->new_for_request('GET' => $path);
    Dancer::SharedData->request($request);

    my $resp = Dancer::Renderer::get_file_response();
    return $resp if $resp;

    my $error = Dancer::Error->new(
        code    => 404,
        message => "No such file: `$path'"
    );
    Dancer::Response::set($error->render);
}

sub template {
    my ($view, $tokens, $options) = @_;

    ($tokens, $options, my $app) = _prepare_tokens_options($tokens, $options);

    my $content;
    if ($view) {
        $content = _apply_renderer($view, $tokens, $options, $app);
        if (! defined $content) {
            my $error = Dancer::Error->new(
                code    => 404,
                message => "Page not found",
            );
            return Dancer::Response::set($error->render);
        }
    } else {
        $content = delete $options->{content};
    }

    my $full_content = _apply_layout($content, $tokens, $options, $app);
    defined $full_content
      and return $full_content;

    my $error = Dancer::Error->new(
        code    => 404,
        message => "Page not found",
    );
    return Dancer::Response::set($error->render);

}

sub apply_renderer {
    my ($view, $tokens, $options) = @_;
    return _apply_renderer($view, _prepare_tokens_options($tokens, $options));
}

sub _apply_renderer {
    my ($view, $tokens, $options, $app) = @_;

    $view = Dancer::Template->engine->view($view);
    -r $view or return;

    $_->($tokens) for (@{$app->registry->hooks->{before_template}});

    my $content = Dancer::Template->engine->render($view, $tokens);
    return $content;
}

# new name :
sub apply_layout {
    my ($content, $tokens, $options) = @_;
    return _apply_layout($content, _prepare_tokens_options($tokens, $options));
}

sub render_with_layout {
    carp "'render_with_layout' is DEPRECATED, use 'apply_layout' instead";
    my $content = Dancer::Helpers::apply_layout(@_);
    if (! defined $content) {
        my $error = Dancer::Error->new(
            code    => 404,
            message => "Page not found",
        );
        return Dancer::Response::set($error->render);
    }
    return $content;
}

sub _apply_layout {
    my ($content, $tokens, $options, $app) = @_;

   # If 'layout' was given in the options hashref, use it if it's a true value,
   # or don't use a layout if it was false (0, or undef); if layout wasn't
   # given in the options hashref, go with whatever the current layout setting
   # is.
    my $layout =
      exists $options->{layout}
      ? ($options->{layout} ? $options->{layout} : undef)
      : $app->setting('layout');

    defined $content or return;

    defined $layout or return $content;

    my $full_content =
      Dancer::Template->engine->layout($layout, $tokens, $content);
    return $full_content;
}

sub _prepare_tokens_options {
    my ($tokens, $options) = @_;

    $options ||= {};

    # these are the default tokens provided for template processing
    $tokens ||= {};
    $tokens->{dancer_version} = $Dancer::VERSION;
    $tokens->{settings}       = Dancer::Config->settings;
    $tokens->{request}        = Dancer::SharedData->request;
    $tokens->{params}         = Dancer::SharedData->request->params;

    setting('session')
      and $tokens->{session} = Dancer::Session->get;

    my $app = Dancer::App->current;

    return ($tokens, $options, $app);
}

sub error {
    my ($class, $content, $status) = @_;
    $status ||= 500;
    my $error = Dancer::Error->new(code => $status, message => $content);
    Dancer::Response::set($error->render);
}

sub redirect {
    my ($destination, $status) = @_;
    if ($destination =~ m!^(\w://)?/!) {

        # no absolute uri here, build one, RFC 2616 forces us to do so
        my $request = Dancer::SharedData->request;
        $destination = $request->uri_for($destination, {}, 1);
    }
    Dancer::Response::status($status || 302);
    Dancer::Response::headers('Location' => $destination);
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
