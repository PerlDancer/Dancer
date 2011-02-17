package Dancer::MIME;

use strict;
use warnings;
use base 'Dancer::Object::Singleton';

use MIME::Types;

# Initialise MIME::Types at compile time, to ensure it's done before
# the fork in a preforking webserver like mod_perl or Starman. Not
# doing this leads to all MIME types being returned as "text/plain",
# as MIME::Types fails to load its mappings from the DATA handle. See
# t/04_static_file/003_mime_types_reinit.t and GH#136.
BEGIN {
        MIME::Types->new(only_complete => 1);
}

__PACKAGE__->attributes( qw/mime_type aliases/ );

sub init {
    my ($class, $instance) = @_;

    $instance->mime_type(MIME::Types->new(only_complete => 1));
    $instance->aliases({});
}

# if not used with care these two methods can create cyclic structures.
# would prefer not to burn CPU testing for that, but I can...
sub add_mime_type {
    my ($self, $name, $mime_type) = @_;
    return $self->add_mime_alias($name => $mime_type);
}

sub add_mime_alias {
    my ($self, $alias, $name) = @_;
    $self->aliases->{$alias} = $name;
    return $name;
}

sub mime_type_for {
    my ($self, $content_type) = @_;

    my $i;
    while (exists($self->aliases->{$content_type})) {
        last if $i++ > 10; # 10 redirects is more than enough
        $content_type = $self->aliases->{$content_type}
    }

    # expect it not to be a "final" content_type type unless it contains
    # at least one slash
    if ($content_type !~ m!/!) {
        my $type_def = $self->mime_type->mimeTypeOf(lc $content_type);
        if ($type_def) {
            $content_type = $type_def->type;
        } else {
            $content_type = 'text/plain'; #sensible default
        }
    }
    return $content_type;
}

42;


=head1 NAME

Dancer::MIME - Singleton object to handle MimeTypes

=head1 SYNOPSIS

    # retrieve object instance
    my $mime = Data::MIME->instance();

    # add non standard mime type
    $mime->add_mime_type( foo => "text/foo" );

    # add an alias
    $mime->add_mime_alias( bar => "foo" );

    # get mime type for standard or non standard types
    $nonstandard_type = $mime->mime_type_for('foo');
    $standard_type = $mime->mime_type_for('svg');
    Dancer::Response->status; # 200

=head1 PUBLIC API

=head2 instance

    my $mime = Dancer::MIME->instance();

return the Dancer::MIME instance object.

=head2 add_mime_type

    $mime->add_mime_type( foo => "text/foo" );

Adds a non standard mime type.

=head2 add_mime_alias

    $mime->add_mime_alias( my_jpg => 'jpg' );

Add an alias to a standard or non standard mime type.

=head2 mime_type_for

    $mime->mime_type_for( 'jpg' );

Retrieve the mime type for a standard or non standard mime type.

=head2 aliases

    $my_aliases = $mime->aliases;

Retrieve the full hash table of added mime types and aliases.

=cut
