package Dancer::Serializer;
# ABSTRACT: serializer wrapper for Dancer

=head1 DESCRIPTION

This module is the wrapper that provides support for different
serializers.

=cut
use strict;
use warnings;
use Dancer::ModuleLoader;
use Dancer::Engine;
use Dancer::Factory::Hook;
use Dancer::Error;
use Dancer::SharedData;

Dancer::Factory::Hook->instance->install_hooks(qw/before_deserializer after_deserializer/);

my $_engine;

=method engine

Returns the current serializer engine.

=cut
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

=method process_response

Takes a response object and checks whether or not it should be
serialized. Returns an error object if the serializer fails.

=cut
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

=method process_request

Deserialize input params in the request body, if matching the
Serializer's content-type.

=cut
sub process_request {
    my ($class, $request) = @_;

    Dancer::Factory::Hook->execute_hooks('before_deserializer');

    return $request unless engine;
    return $request
      unless engine->support_content_type($request->content_type);

    return $request unless $request->is_put || $request->is_post;

    my $old_params = $request->params('body');

    # try to deserialize
    my $new_params;
    eval { $new_params = engine->deserialize($request->body) };
    if ($@) {
        Dancer::Logger::core "Unable to deserialize request body with "
          . engine()
          . " : \n$@";
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

=head1 USAGE

=head2 Default engine

The default serializer used by Dancer::Serializer is
L<Dancer::Serializer::JSON>.
You can choose another serializer by setting the B<serializer> configuration
variable.

=head2 Configuration

The B<serializer> configuration variable tells Dancer which serializer to use
to deserialize request and serialize response.

You change it either in your config.yml file:

    serializer: "YAML"

Or in the application code:

    # setting JSON as the default serializer
    set serializer => 'JSON';

=cut
