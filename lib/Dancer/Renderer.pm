package Dancer::Renderer;
our $AUTHORITY = 'cpan:SUKRIA';
# ABSTRACT: Rendering class for Dancer
$Dancer::Renderer::VERSION = '1.3202';
use strict;
use warnings;
use Carp;
use HTTP::Headers;
use HTTP::Date qw( str2time time2str );
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
use Dancer::Exception qw(:all);

Dancer::Factory::Hook->instance->install_hooks(
    qw/before after before_serializer after_serializer before_file_render after_file_render/
);

sub render_file { get_file_response() }

sub render_action {
    my $class = shift;
    my $resp = $class->get_action_response();
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

    if (Dancer::Config::setting('server_tokens')) {
        $response->{headers} ||= HTTP::Headers->new;
        my $powered_by = "Perl Dancer " . Dancer->VERSION;
        $response->header('X-Powered-By' => $powered_by);
        $response->header('Server'       => $powered_by);
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
    my $class = shift;
    my $depth = shift || 1;

    # save the request before the filters are ran
    my $request = Dancer::SharedData->request;
    my ($method, $path) = ($request->method, $request->path_info);

    # look for a matching route handler, for the given request
    my $handler =
      Dancer::App->find_route_through_apps(Dancer::SharedData->request);

    my $app = ($handler && $handler->app) ? $handler->app : Dancer::App->current();

    # run the before filters, before "running" the route handler
    Dancer::Factory::Hook->instance->execute_hooks('before', $handler);

    # recurse if something has changed
    my $MAX_RECURSIVE_LOOP = 10;
    if (   ($path ne Dancer::SharedData->request->path_info)
        || ($method ne Dancer::SharedData->request->method))
    {
        if ($depth > $MAX_RECURSIVE_LOOP) {
            raise core_renderer => "infinite loop detected, "
              . "check your route/filters for "
              . $method . ' '
              . $path;
        }
        return $class->get_action_response($depth + 1);
    }

    # redirect immediately - skip route execution
    my $response = Dancer::SharedData->response();
    if (defined $response && (my $status = $response->status)) {
        if ($status == 302 || $status == 301) {
            $class->serialize_response_if_needed();
            Dancer::Factory::Hook->instance->execute_hooks('after', $response);
            return $response;
        }
    }

    # execute the action
    if ($handler) {
        # a response may exist, produced by a before filter
        return $class->serialize_response_if_needed() if defined $response && $response->exists;
        # else, get the route handler's response
        Dancer::App->current($handler->{app});
        try {
            $handler->run($request);
            $class->serialize_response_if_needed();
        } continuation {
            my ($continuation) = @_;
            # If we have a Route continuation, run the after hook, then
            # propagate the continuation
            my $resp = Dancer::SharedData->response();
            Dancer::Factory::Hook->instance->execute_hooks('after', $resp);
            $continuation->rethrow();
        };
        my $resp = Dancer::SharedData->response();
        Dancer::Factory::Hook->instance->execute_hooks('after', $resp);
        return $resp;
    }
    else {
        return undef;    # 404
    }
}

sub render_autopage {
    return unless Dancer::setting('auto_page');

    my $request = Dancer::SharedData->request;
    my $path = $request->path_info;

    # See if we find a matching view for this request, if so, render it
    my $viewpath = $path;
    $viewpath =~ s{^/}{};
    my $view = Dancer::engine('template')->view($viewpath) || '';

    if ($view && -f $view) {
        # A view exists for the path requested, go ahead and render it:
        return _autopage_response($viewpath);
    }

    # Try appending "index" and looking again
    $view = Dancer::engine('template')->view(
        Dancer::FileUtils::path($viewpath, 'index')
    )|| '';
    Dancer::error("Looking for $viewpath/index - got $view");
    if ($view && -f $view) {
        return _autopage_response(
            Dancer::FileUtils::path($viewpath, 'index')
        );
    }

    return;
}
sub _autopage_response {
    my $viewpath = shift;
    my $response = Dancer::Response->new;
    $response->status(200);
    $response->content(
        Dancer::template($viewpath)
    );
    $response->header( 'Content-Type' => 'text/html' );
    return $response;
}

sub serialize_response_if_needed {
    my $response = Dancer::SharedData->response();

    if (Dancer::App->current->setting('serializer') && $response->content()){
        Dancer::Factory::Hook->execute_hooks('before_serializer', $response);
        try {
            Dancer::Serializer->process_response($response);
        } continuation {
            my ($continuation) = @_;
            # If we have a Route continuation, run the after hook, then
            # propagate the continuation
            Dancer::Factory::Hook->execute_hooks('after_serializer', $response);
            $continuation->rethrow();
        };
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
    # and then returning a 404
    my $public = defined $app->setting('public') ?
                 $app->setting('public')         :
                 '';

    my $static_file = path( $public, $path_info );

    return if ( !$static_file
        || index( $static_file, ( path($public) || '' ) ) != 0 );

    return Dancer::Renderer->get_file_response_for_path( $static_file, undef,
        $request->content_type );
}

sub get_file_response_for_path {
    my ($class, $static_file, $status, $mime) = @_;

    if ( -f $static_file ) {
        Dancer::Factory::Hook->execute_hooks( 'before_file_render',
            $static_file );

        my $response = Dancer::SharedData->response() || Dancer::Response->new();

        # handle If-Modified-Since
        my $last_modified = (stat $static_file)[9];
        my $since = str2time(Dancer::SharedData->request->env->{HTTP_IF_MODIFIED_SINCE});
        if( defined $since && $since >= $last_modified ) {
            $response->status( 304 );
            $response->content( '' );
            return $response;
        }

        my $fh = open_file( '<', $static_file );
        binmode $fh;
        $response->status($status) if ($status);
        $response->header( 'Last-Modified' => time2str( $last_modified ) );
        $response->header('Content-Type' => (($mime && _get_full_mime_type($mime)) ||
                                             Dancer::SharedData->request->content_type ||
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

__END__

=pod

=encoding UTF-8

=head1 NAME

Dancer::Renderer - Rendering class for Dancer

=head1 VERSION

version 1.3202

=head1 AUTHOR

Dancer Core Developers

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Alexis Sukrieh.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
