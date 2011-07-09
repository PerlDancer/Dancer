package Dancer::Renderer;

use strict;
use warnings;
use Carp;
use HTTP::Headers;
use Dancer::Route;
use Dancer::HTTP;
use Dancer::Cookie;
use Dancer::Factory::Hook;
use Dancer::Cookies;
use Dancer::Request;
use Dancer::Response;
use Dancer::Serializer;
use Dancer::Config 'setting';
use Dancer::FileUtils qw(path path_or_empty dirname read_file_content open_file);
use Dancer::SharedData;
use Dancer::Logger;
use Dancer::MIME;

Dancer::Factory::Hook->instance->install_hooks(
    qw/before after before_serializer after_serializer before_file_render after_file_render/
);

sub render_file { get_file_response() }

sub render_action {
    my $resp = get_action_response();
    return (defined $resp)
      ? response_with_headers()
      : undef;
}

sub render_error {
    my ($class, $error_code) = @_;

    my $app         = Dancer::App->current;
    my $static_file = path($app->setting('public'), "$error_code.html");
    my $response    = Dancer::Renderer->get_file_response_for_path(
        $static_file => $error_code);
    return $response if $response;

    return Dancer::Response->new(
        status  => $error_code,
        headers => ['Content-Type' => 'text/html'],
        content => Dancer::Renderer->html_page(
                "Error $error_code" => "<h2>Unable to process your query</h2>"
              . "The page you requested is not available"
        )
    );
}

# Takes a response object and add default headers
sub response_with_headers {
    my $response = Dancer::SharedData->response();

    $response->{headers} ||= HTTP::Headers->new;
    $response->header('X-Powered-By' => "Perl Dancer ${Dancer::VERSION}");

    return $response;
}

sub html_page {
    my ($class, $title, $content, $style) = @_;
    $style ||= 'style';

    my $template = $class->templates->{'default'};
    my $ts       = Dancer::Template::Simple->new;

    return $ts->render(
        \$template,
        {   title   => $title,
            style   => $style,
            version => $Dancer::VERSION,
            content => $content
        }
    );
}

sub get_action_response {
    my $depth = shift || 1;

    # save the request before the filters are ran
    my $request = Dancer::SharedData->request;
    my ($method, $path) = ($request->method, $request->path_info);

    # look for a matching route handler, for the given request
    my $handler =
      Dancer::App->find_route_through_apps(Dancer::SharedData->request);

    my $app = ($handler && $handler->app) ? $handler->app : Dancer::App->current();

    # run the before filters, before "running" the route handler
    Dancer::Factory::Hook->instance->execute_hooks('before');

    # recurse if something has changed
    my $MAX_RECURSIVE_LOOP = 10;
    if (   ($path ne Dancer::SharedData->request->path_info)
        || ($method ne Dancer::SharedData->request->method))
    {
        if ($depth > $MAX_RECURSIVE_LOOP) {
            croak "infinite loop detected, "
              . "check your route/filters for "
              . $method . ' '
              . $path;
        }
        return get_action_response($depth + 1);
    }

    # redirect immediately - skip route execution
    my $response = Dancer::SharedData->response();
    if (defined $response && (my $status = $response->status)) {
        if ($status == 302 || $status == 301) {
            serialize_response_if_needed();
            return $response;
        }
    }

    # execute the action
    if ($handler) {
        # a response may exist, produced by a before filter
        return serialize_response_if_needed() if defined $response && $response->exists;
        # else, get the route handler's response
        Dancer::App->current($handler->{app});
        $handler->run($request);
        serialize_response_if_needed();
        my $resp = Dancer::SharedData->response();
        Dancer::Factory::Hook->instance->execute_hooks('after', $resp);
        return $resp;
    }
    else {
        return undef;    # 404
    }
}

sub serialize_response_if_needed {
    my $response = Dancer::SharedData->response();

    if (Dancer::App->current->setting('serializer') && $response->content()){
        Dancer::Factory::Hook->execute_hooks('before_serializer', $response);
        Dancer::Serializer->process_response($response);
        Dancer::Factory::Hook->execute_hooks('after_serializer', $response);
    }
    return $response;
}

sub get_file_response {
    my $request   = Dancer::SharedData->request;
    my $path_info = $request->path_info;

    # requests that have \0 in path are forbidden
    if ( $path_info =~ /\0/ ) {
        _bad_request();
        return 1;
    }

    my $app = Dancer::App->current;
    # TODO: this should be later removed with a check whether the file exists
    # and then returning a 404, path_or_empty should be removed
    my $static_file = path_or_empty( $app->setting('public'), $path_info );

    return if ( !$static_file
        || index( $static_file, path( $app->setting('public') ) ) != 0 );

    return Dancer::Renderer->get_file_response_for_path( $static_file, undef,
        $request->content_type );
}

sub get_file_response_for_path {
    my ($class, $static_file, $status, $mime) = @_;
    $status ||= 200;

    if ( -f $static_file ) {
        Dancer::Factory::Hook->execute_hooks( 'before_file_render',
            $static_file );

        my $fh = open_file( '<', $static_file );
        binmode $fh;
        my $response = Dancer::SharedData->response() || Dancer::Response->new();
        $response->status($status);
        $response->header('Content-Type' => (($mime && _get_full_mime_type($mime)) ||
                                             _get_mime_type($static_file)));
        $response->content($fh);

        Dancer::Factory::Hook->execute_hooks( 'after_file_render', $response );

        return $response;
    }
    return;
}

# private
sub _get_full_mime_type {
    my $mime = Dancer::MIME->instance();
    return $mime->name_or_type(shift @_);
}

sub _get_mime_type {
    my $file = shift;
    my $mime = Dancer::MIME->instance();
    return $mime->for_file($file);
}

sub _bad_request{
    my $response = Dancer::SharedData->response() || Dancer::Response->new();
    $response->status(400);
    $response->content('Bad Request');
}

# set of builtin templates needed by Dancer when rendering HTML pages
sub templates {
    my $charset = setting('charset') || 'UTF-8';
    {   default =>
          '<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN"
        "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html>
<head>
<title><% title %></title>
<link rel="stylesheet" href="/css/<% style %>.css" />
<meta http-equiv="Content-type" content="text/html; charset=' . $charset
          . '" />
</head>
<body>
<h1><% title %></h1>
<div id="content">
<% content %>
</div>
<div id="footer">
Powered by <a href="http://perldancer.org/">Dancer</a> <% version %>
</div>
</body>
</html>',
    };
}


1;
