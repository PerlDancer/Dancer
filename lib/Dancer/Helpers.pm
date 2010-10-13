package Dancer::Helpers;

# helpers are function intended to be called from a route handler. They can
# alter the response of the route handler by changing the head or the body of
# the response.

use strict;
use warnings;

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

    my $app = Dancer::App->current;

    $options ||= {layout => 1};
    my $layout = $app->setting('layout');
    undef $layout unless $options->{layout};

    $tokens ||= {};
    $tokens->{request} = Dancer::SharedData->request;
    $tokens->{params}  = Dancer::SharedData->request->params;
    if (setting('session')) {
        $tokens->{session} = Dancer::Session->get;
    }

    $view = Dancer::Template->engine->view($view);

    if (!-r $view) {
        my $error = Dancer::Error->new(
            code    => 404,
            message => "Page not found",
        );
        return Dancer::Response::set($error->render);
    }

    $_->($tokens) for (@{$app->registry->hooks->{before_template}});

    my $content = Dancer::Template->engine->render($view, $tokens);
    return $content if not defined $layout;

    my $full_content =
      Dancer::Template->engine->layout($layout, $tokens, $content);
    return $full_content;
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
