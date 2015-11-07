package Dancer::Serializer;
our $AUTHORITY = 'cpan:SUKRIA';
#ABSTRACT: serializer wrapper for Dancer
$Dancer::Serializer::VERSION = '1.3202';
# Factory for serializer engines

use strict;
use warnings;
use Dancer::ModuleLoader;
use Dancer::Engine;
use Dancer::Factory::Hook;
use Dancer::Error;
use Dancer::SharedData;

Dancer::Factory::Hook->instance->install_hooks(qw/before_deserializer after_deserializer/);

my $_engine;

sub engine {
    $_engine
      and return $_engine;
    # don't create a new serializer unless it's defined in the config
    # (else it's created using json, and that's *not* what we want)
    my $serializer_name = Dancer::App->current->setting('serializer');
    $serializer_name
      and return Dancer::Serializer->init($serializer_name);
    return;
}

sub init {
    my ($class, $name, $config) = @_;
    $name ||= 'JSON';
    $_engine = Dancer::Engine->build('serializer' => $name, $config);
    return $_engine;
}

# takes a response object and checks whether or not it should be
# serialized.
# returns an error object if the serializer fails
sub process_response {
    my ($class, $response) = @_;

    my $content = $response->{content};

    if (ref($content) && (ref($content) ne 'GLOB')) {
        local $@;
        eval { $content = engine->serialize($content) };

        # the serializer failed, replace the response with an error object
        if ($@) {
            my $error = Dancer::Error->new(
                code    => 500,
                message => "Serializer ("
                  . ref($_engine) . ") "
                  . "failed at serializing "
                  . $response->{content} . ":\n$@",
            );
            $response = $error->render;
        }

        # the serializer succeeded, alter the response object accordingly
        else {
            $response->header('Content-Type' => engine->content_type);
            $response->{content} = $content;
        }
    }

    return $response;
}

# deserialize input params in the request body, if matching the Serializer's
# content-type.
sub process_request {
    my ($class, $request) = @_;

    Dancer::Factory::Hook->execute_hooks('before_deserializer');

    return $request unless engine;

    # Content-Type may contain additional parameters
    # (http://www.w3.org/Protocols/rfc2616/rfc2616-sec3.html#sec3.7)
    # which should be safe to ignore at this level.
    # So accept either e.g. text/xml or text/xml; charset=utf-8
    my $content_type = $request->content_type;
    $content_type =~ s/ \s* ; .+ $ //x;
    return $request unless engine->support_content_type($content_type);

    return $request
      unless $request->is_put 
          or $request->is_post 
          or $request->is_patch 
          or $request->is_delete;

    my $old_params = $request->params('body');

    # try to deserialize
    my $new_params;
    eval {
        $new_params = engine->deserialize($request->body)
    };
    if ($@) {
        Dancer::Logger::core "Unable to deserialize request body with "
          . engine()
          . " : \n$@";
        return $request;
    }

    if(!ref $new_params or ref $new_params ne 'HASH'){
        return $request;
    }

    (keys %$old_params)
      ? $request->_set_body_params({%$old_params, %$new_params})
      : $request->_set_body_params($new_params);

    Dancer::Factory::Hook->execute_hooks('after_deserializer');

    return $request;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dancer::Serializer - serializer wrapper for Dancer

=head1 VERSION

version 1.3202

=head1 DESCRIPTION

This module is the wrapper that provides support for different
serializers.

=head1 USAGE

=head2 Configuration

The B<serializer> configuration variable tells Dancer which serializer to use
to deserialize request and serialize response.

You change it either in your config.yml file:

    serializer: "YAML"

Or in the application code:

    # setting JSON as the default serializer
    set serializer => 'JSON';

In your routes you can access parameters just like any route.

When in a route you return a Perl data structure, it will be
serialized automatically to the respective serialized engine (for
instance, C<JSON>).

For C<PUT> and C<POST> methods you can access the C<< request->body >> as
a string, and you can unserialize it, if you really need to. If your
content type is recognized by the serializer, C<< request->body >> will be
unserialized automatically, and it will be available as a standard
parameter.

For instance, if you call

 curl -X POST -H 'Content-Type: application/json' -d '{"id":"bar"}' /foo

your C<foo> route can do something like:

  post "/foo" => {
     my $id = param('id'); # gets "bar"
     #  ...
  }

=head1 AUTHORS

This module has been written by Alexis Sukrieh and Franck Cuny.
See the AUTHORS file that comes with this distribution for details.

=head1 LICENSE

This module is free software and is released under the same terms as Perl
itself.

=head1 SEE ALSO

See L<Dancer> for details about the complete framework.

=head1 AUTHOR

Dancer Core Developers

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Alexis Sukrieh.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
