package Dancer::Renderer;

use strict;
use warnings;
use Carp;
use HTTP::Headers;
use Dancer::Route;
use Dancer::HTTP;
use Dancer::Cookie;
use Dancer::Cookies;
use Dancer::Request;
use Dancer::Response;
use Dancer::Serializer;
use Dancer::Config 'setting';
use Dancer::FileUtils qw(path dirname read_file_content open_file);
use Dancer::SharedData;
use Dancer::Logger;
use MIME::Types;

BEGIN {
    MIME::Types->new(only_complete => 1);
}

sub render_file {
    return get_file_response();
}

sub render_action {
    my $resp = get_action_response();
    return (defined $resp)
      ? response_with_headers($resp)
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
    my $response = shift;

    $response->{headers} ||= HTTP::Headers->new;
    $response->header('X-Powered-By' => "Perl Dancer ${Dancer::VERSION}");

    # add cookies
    foreach my $c (keys %{Dancer::Cookies->cookies}) {
        my $cookie = Dancer::Cookies->cookies->{$c};
        if (Dancer::Cookies->has_changed($cookie)) {
            $response->header('Set-Cookie' => $cookie->to_header);
        }
    }

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
    my $response;

    # save the request before the filters are ran
    my $request = Dancer::SharedData->request;
    my ($method, $path) = ($request->method, $request->path_info);

    # look for a matching route handler, for the given request
    my $handler =
      Dancer::App->find_route_through_apps(Dancer::SharedData->request);

    # run the before filters, before "running" the route handler
    my $app = Dancer::App->current;
    $app = $handler->{app} if ($handler);
    $_->() for @{$app->registry->hooks->{before}};

    # recurse if something has changed
    my $limit              = 0;
    my $MAX_RECURSIVE_LOOP = 10;
    if (   ($path ne Dancer::SharedData->request->path_info)
        || ($method ne Dancer::SharedData->request->method))
    {
        $limit++;
        if ($limit > $MAX_RECURSIVE_LOOP) {
            croak "infinite loop detected, "
              . "check your route/filters for "
              . $method . ' '
              . $path;
        }
        return get_action_response();
    }

    # redirect immediately - skip route execution
    if (my $status = Dancer::Response->status) {
        if ($status == 302 || $status == 301) {
            return serialize_response_if_needed(Dancer::Response->current);
        }
    }

    # execute the action
    if ($handler) {

        # a response may exist, produced by a before filter
        return serialize_response_if_needed(Dancer::Response->current)
          if Dancer::Response->exists;

        # else, get the route handler's response
        Dancer::App->current($handler->app);
        $response = $handler->run($request);
        $response = serialize_response_if_needed($response);
        $_->($response) for (@{$app->registry->hooks->{after}});
        return $response;
    }
    else {
        return;    # 404
    }
}

sub serialize_response_if_needed {
    my ($response) = @_;
    $response = Dancer::Serializer->process_response($response)
      if Dancer::App->current->setting('serializer') && $response->content();
    return $response;
}


sub get_file_response {
    my $request     = Dancer::SharedData->request;
    my $path_info   = $request->path_info;
    my $app         = Dancer::App->current;
    my $static_file = path($app->setting('public'), $path_info);
    return Dancer::Renderer->get_file_response_for_path($static_file);
}

sub get_file_response_for_path {
    my ($class, $static_file, $status) = @_;
    $status ||= 200;

    if (-f $static_file) {
        my $fh = open_file('<', $static_file);
        binmode $fh;

        return Dancer::Response->new(
            status  => $status,
            headers => ['Content-Type' => get_mime_type($static_file)],
            content => $fh
        );
    }
    return;
}

# private

sub get_mime_type {
    my ($filename) = @_;
    my @tokens = reverse(split(/\./, $filename));
    my $ext = $tokens[0];

    # first check user configured mime types
    my $mime = Dancer::Config::mime_types($ext);
    return $mime if defined $mime;

    # user has not specified a mime type, so ask MIME::Types
    $mime = MIME::Types->new(only_complete => 1)->mimeTypeOf($ext);

    # default to text/plain
    return defined($mime) ? $mime : 'text/plain';
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
