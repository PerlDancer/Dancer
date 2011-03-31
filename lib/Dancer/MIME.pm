package Dancer::MIME;

use strict;
use warnings;
use base 'Dancer::Object::Singleton';

use Dancer::Config;
use Dancer::Deprecation;

use Carp;
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

sub default {
    my $instance = shift;
    return Dancer::Config::setting("default_mime_type") || "application/data";
}

sub add_type {
    my ($self, $alias, $name) = @_;
    $self->aliases->{$alias} = $name;
    return;
}

sub add_alias {
    my($self, $alias, $orig) = @_;
    my $type = $self->for_alias($orig) || croak "Can't find a mime type for $orig to alias $alias to";
    $self->add_type($alias, $type);
    return;
}

sub for_file {
    my ($mime, $filename) = @_;
    my ($ext) = $filename =~ /\.([^.]+)$/;
    return 'application/data' unless $ext;

    return $mime->for_alias($ext);
}

sub name_or_type {
    my($self, $name) = @_;

    return $name if $name =~ m{/};  # probably a mime type
    return $self->for_alias($name);
}

sub for_alias {
    my ($self, $name) = @_;
    return $self->aliases->{$name} || $self->mime_type->mimeTypeOf(lc $name) || $self->default;
}

sub add_mime_type {
    my ($self, $name, $type) = @_;
    Dancer::Deprecation->deprecated(feature => 'add_mime_type',
                                    reason => 'use the new "add" method');
    $self->add_type($name => $type);
}

sub add_mime_alias {
    my ($self, $alias, $orig) = @_;
    Dancer::Deprecation->deprecated(feature => 'add_mime_alias',
                                    reason => 'use the new "add" method');
    $self->add_alias($alias => $orig);
}

sub mime_type_for {
    my ($self, $content_type) = @_;
    Dancer::Deprecation->deprecated(feature => 'mime_type_for',
                                    reason => 'use the new "for_alias" method');
    return $self->for_alias($content_type);
}

42;


=head1 NAME

Dancer::MIME - Singleton object to handle MimeTypes

=head1 SYNOPSIS

    # retrieve object instance
    my $mime = Data::MIME->instance();

    # return a hash reference of aliases
    $mime->aliases;

    # return the default mime-type for unknown files
    $mime->default

    # set the default mime-type with Dancer::Config or Dancer, like
    set default_mime_type => "text/plain";
    # or directly in your config.yml file.

    # add non standard mime type
    $mime->add_type( foo => "text/foo" );

    # add an alias
    $mime->add_alias( bar => "foo" );

    # get mime type for standard or non standard types
    $nonstandard_type = $mime->for_alias('foo');
    $standard_type    = $mime->for_alias('svg');

    # get mime type for a file (given the extension)
    $mime_type = $mime->for_file("foo.bar");

=head1 PUBLIC API

=head2 instance

    my $mime = Dancer::MIME->instance();

return the Dancer::MIME instance object.

=head2 add_type

    # add nonstandard mime type
    $mime->add_type( foo => "text/foo" );

Add a non standard mime type or overrides an existing one.

=head2 add_alias

    # add alias to standard or previous alias
    $mime->add_alias( my_jpg => 'jpg' );

Adds an alias to an existing mime type.

=head2 for_alias

    $mime->for_alias( 'jpg' );

Retrieve the mime type for a standard or non standard mime type.

=head2 for_file

    $mime->for_file( 'file.jpg' );

Retrieve the mime type for a file, based on a file extension.

=head2 aliases

    $my_aliases = $mime->aliases;

Retrieve the full hash table of added mime types and aliases.

=head2 name_or_type

    my $type = $mime->name_or_type($thing);

Resolves the $thing into a content $type whether it's the name of a
MIME type like "txt" or already a mime type like "text/plain".

=head1 DEPRECATED API

=head2 add_mime_type

Check the new C<add> method.

=head2 add_mime_alias

Check the new C<add> method.

=head2 mime_type_for

Check the new C<for_alias> method.

=head1 AUTHORS

This module has been written and rewritten by different people from
Dancer project.

=head1 LICENCE

This module is released under the same terms as Perl itself.

=head1 SEE ALSO

L<Dancer>

=cut

