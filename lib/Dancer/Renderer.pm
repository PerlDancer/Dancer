package Dancer::Renderer;

use strict;
use warnings;

use Dancer::Route;
use Dancer::HTTP;
use Dancer::Cookie;
use Dancer::Cookies;
use Dancer::Request;
use Dancer::Response;
use Dancer::Serializer;
use Dancer::Config 'setting';
use Dancer::FileUtils qw(path dirname read_file_content);
use Dancer::SharedData;
use Dancer::Logger;
use MIME::Types;

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

    my $static_file = path(setting('public'), "$error_code.html");
    my $response = Dancer::Renderer->get_file_response_for_path(
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

    $response->{headers} ||= [];
    push @{$response->{headers}},
      ('X-Powered-By' => "Perl Dancer ${Dancer::VERSION}");

    # add cookies
    foreach my $c (keys %{Dancer::Cookies->cookies}) {
        my $cookie = Dancer::Cookies->cookies->{$c};
        if (Dancer::Cookies->has_changed($cookie)) {
            push @{$response->{headers}}, ('Set-Cookie' => $cookie->to_header);
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
    my $request = Dancer::SharedData->request;
    my $path    = $request->path_info;
    my $method  = $request->method;
    my $handler = Dancer::Route->find($path, $method, $request);

    # init the request and build the params
    Dancer::Route->build_params($handler, $request);
    Dancer::SharedData->request($request);

    # run the before filters
    # if a filter has set a response, return it now.
    Dancer::Route->run_before_filters;
    if (Dancer::Response->exists) {
        $response = serialize_response_if_needed(Dancer::Response->current);
    }

    # recurse if something has changed
    my $limit = 0;
    my $MAX_RECURSIVE_LOOP = 10;
    if (($path ne Dancer::SharedData->request->path) ||
        ($method ne Dancer::SharedData->request->method)) {
        $limit++;
        if ($limit > $MAX_RECURSIVE_LOOP) {
            die "infinite loop detected, check your route/filters for '$method $path'";
        }
        return get_action_response();
    }

    # execute the action
    if ($handler) {
        # if a filter has set a response before, return it
        return $response if defined $response;
        undef $response;

        $response = Dancer::Route->call($handler);
        Dancer::Logger->core("route: ".$handler->{route});

        return serialize_response_if_needed($response); #200
    }
    else {
        return undef; # 404
    }
}

sub serialize_response_if_needed {
    my ($response) = @_;
    $response = Dancer::Serializer->process_response($response)
        if setting('serializer') && $response->{content};
    return $response;
}


sub get_file_response() {
    my $request     = Dancer::SharedData->request;
    my $path        = $request->path_info;
    my $static_file = path(setting('public'), $path);
    return Dancer::Renderer->get_file_response_for_path($static_file);
}

sub get_file_response_for_path {
    my ($class, $static_file, $status) = @_;
    $status ||= 200;

    if (-f $static_file) {
        open my $fh, "<", $static_file;
        binmode $fh;

        return Dancer::Response->new(
            status  => $status,
            headers => ['Content-Type' => get_mime_type($static_file)],
            content => $fh
        );
    }
    return undef;
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
          '<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" lang="en-US" xml:lang="en-US">
<head>
<title><% title %></title>
<link rel="stylesheet" type="text/css" href="/css/<% style %>.css" />
<meta http-equiv="Content-Type" content="text/html; charset='.$charset.'" />
</head>
<body>
<h1><% title %></h1>
<div id="content">
<p><% content %></p>
</div>
<div id="footer">
Powered by <a href="http://perldancer.org/">Dancer</a> <% version %>
</div>
</body>
</html>',
    }
}


1;
