package Dancer::Helpers;

# helpers are function intended to be called from a route handler. They can
# alter the response of the route handler by changing the head or the body of
# the response.

use strict;
use warnings;

use Dancer::Response;
use Dancer::Config 'setting';
use Dancer::FileUtils 'path';
use Dancer::SharedData;
use Dancer::Exceptions;
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
    $options ||= {layout => 1};
    my $layout = setting('layout');
    undef $layout unless $options->{layout};

    $view .= ".tt" if $view !~ /\.tt$/;
    $view = path(setting('views'), $view);

    $tokens ||= {};
    $tokens->{params}  = Dancer::SharedData::params();
    $tokens->{request} = Dancer::SharedData->request;

    my $content = Dancer::Template->engine->render($view, $tokens);
    return $content if not defined $layout;

    $layout .= '.tt' if $layout !~ /\.tt/;
    $layout = path(setting('views'), 'layouts', $layout);
    my $full_content =
      Dancer::Template->engine->render($layout,
        {%$tokens, content => $content});

    return $full_content;
}

sub error {
    my ($class, $content, $status) = @_;
    $status ||= 500;

    my $error = Dancer::Error->new(code => $status, message => $content);
    Dancer::Response::set($error->render);
    halt;
}

sub redirect {
    my ($destination, $status) = @_;

    Dancer::Response::set(
        {   status => $status || 302,
            headers => ['Location' => $destination],
        }
    );

    halt;    # w00t!
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
