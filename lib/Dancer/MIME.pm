package Dancer::MIME;

use strict;
use warnings;
use base 'Dancer::Object::Singleton';

use MIME::Types;

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

    $content_type = $self->aliases->{$content_type}
      if exists($self->aliases->{$content_type});

    # expect it not to be a "final" content_type type unless it slashes
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
