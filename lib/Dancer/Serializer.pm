package Dancer::Serializer;

# Factory for serializer engines

use strict;
use warnings;
use Dancer::ModuleLoader;
use Dancer::Engine;
use Dancer::Error;
use Dancer::SharedData;

my $_engine;
sub engine {$_engine}

sub init {
    my ( $class, $name, $config ) = @_;
    $name ||= 'JSON';
    $_engine = Dancer::Engine->build( 'serializer' => $name, $config );
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
                code => 500,
                message => "Serializer (".ref($_engine).") ".
                    "failed at serializing ".$response->{content}.":\n$@",
            );
            $response = $error->render;
        }

        # the serializer succeeded, alter the response object accordingly
        else {
            $response->update_headers('Content-Type' => engine->content_type);
            $response->{content_type} = engine->content_type;
            $response->{content} = $content;
        }
    }

    return $response;
}

# deserialize input params in the request body, if matching the Serializer's
# content-type.
sub process_request {
    my ($class, $request) = @_;

    return $request unless engine->support_content_type($request->content_type);
    return $request unless $request->is_put || $request->is_post;

    my $old_params = $request->params('body');

    # try to deserialize
    my $new_params;
    eval { $new_params = engine->deserialize($request->body, $request) };
    if ($@) {
        warn "Unable to deserialize request body with ".engine()." : \n$@";
        return $request;
    }

    (keys %$old_params)
        ? $request->_set_body_params({%$old_params, %$new_params})
        : $request->_set_body_params($new_params);

    return $request;
}


1;

__END__

=pod

=head1 NAME

Dancer::Serializer - serializer wrapper for Dancer

=head1 DESCRIPTION

This module is the wrapper that provides support for different
serializers.

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

=head1 AUTHORS

This module has been written by Alexis Sukrieh and Franck Cuny.
See the AUTHORS file that comes with this distribution for details.

=head1 LICENSE

This module is free software and is released under the same terms as Perl
itself.

=head1 SEE ALSO

See L<Dancer> for details about the complete framework.

=cut
