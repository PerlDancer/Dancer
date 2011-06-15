package Dancer::MIME;
# ABSTRACT: singleton object to handle MimeTypes

=head1 SYNOPSIS

    # retrieve object instance
    my $mime = Data::MIME->instance();

    # return a hash reference of user defined types
    my $types = $mime->custom_types;

    # return the default mime-type for unknown files
    $mime->default

    # set the default mime-type with Dancer::Config or Dancer, like
    set default_mime_type => "text/plain";
    # or directly in your config.yml file.

    # add non standard mime type
    $mime->add_type( foo => "text/foo" );

    # add an alias to an existing type
    $mime->add_alias( bar => "foo" );

    # get mime type for standard or non standard types
    $nonstandard_type = $mime->for_name('foo');
    $standard_type    = $mime->for_name('svg');

    # get mime type for a file (given the extension)
    $mime_type = $mime->for_file("foo.bar");

=head1 DESCRIPTION

Simplistic Dancer interface to L<MIME::Types>.

=cut

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

__PACKAGE__->attributes( qw/mime_type custom_types/ );

=method instance

Return the Dancer::MIME instance object.

    my $mime = Dancer::MIME->instance();

=attr custom_types

Retrieve the full hash table of added mime types.

    my $types = $mime->custom_types;

=cut

sub init {
    my ($class, $instance) = @_;

    $instance->mime_type(MIME::Types->new(only_complete => 1));
    $instance->custom_types({});
}

=method default

Returns the default mime type. It can be changed in the configuration
file:

   default_mime_type: foo/bar

You can also C<set> it directly on your code:

   set default_mime_type => 'ugh/zbr';

=cut
sub default {
    my $instance = shift;
    return Dancer::Config::setting("default_mime_type") || "application/data";
}

=method add_type

Add a non standard mime type or overrides an existing one.

    $mime->add_type( foo => "text/foo" );

=cut
sub add_type {
    my ($self, $name, $type) = @_;
    $self->custom_types->{$name} = $type;
    return;
}

=method add_alias

Adds an alias to an existing mime type.

    $mime->add_alias( my_jpg => 'jpg' );

=cut
sub add_alias {
    my($self, $alias, $orig) = @_;
    my $type = $self->for_name($orig);
    $self->add_type($alias, $type);
    return $type;
}

=method for_file

Retrieve the mime type for a file, based on a file extension.

    $mime->for_file( 'file.jpg' );

=cut
sub for_file {
    my ($self, $filename) = @_;
    my ($ext) = $filename =~ /\.([^.]+)$/;
    return $self->default unless $ext;
    return $self->for_name($ext);
}

=method name_or_type

Resolves the $thing into a content $type whether it's the name of a
MIME type like "txt" or already a mime type like "text/plain".

    my $type = $mime->name_or_type($thing);

=cut
sub name_or_type {
    my($self, $name) = @_;

    return $name if $name =~ m{/};  # probably a mime type
    return $self->for_name($name);
}

=method for_name

Retrieve the mime type for a standard or non standard mime type.

    $mime->for_name( 'jpg' );

=cut
sub for_name {
    my ($self, $name) = @_;
    return $self->custom_types->{lc $name}
        || $self->mime_type->mimeTypeOf(lc $name)
        || $self->default;
}


=method add_mime_type

B<DEPRECATED:> Check the new C<add> method.

=cut
sub add_mime_type {
    Dancer::Deprecation->deprecated(feature => 'add_mime_type',
                                    fatal => 1,
                                    reason => 'use the new "add" method');
}

=method add_mime_alias

B<DEPRECATED:> Check the new C<add> method.

=cut
sub add_mime_alias {
    Dancer::Deprecation->deprecated(feature => 'add_mime_alias',
                                    fatal => 1,
                                    reason => 'use the new "add_alias" method');
}

=method mime_type_for

B<DEPRECATED:> Check the new C<for_name> and C<name_or_type> methods.

=cut
sub mime_type_for {
    Dancer::Deprecation->deprecated(feature => 'mime_type_for',
                                    fatal => 1,
                                    reason => 'use the new "name_or_type" method');
}

42;
