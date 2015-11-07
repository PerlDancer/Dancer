package Dancer::MIME;
our $AUTHORITY = 'cpan:SUKRIA';
#ABSTRACT: Singleton object to handle MimeTypes
$Dancer::MIME::VERSION = '1.3202';
use strict;
use warnings;
use base 'Dancer::Object::Singleton';

use Dancer::Config;

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

sub init {
    my ($class, $instance) = @_;

    $instance->mime_type(MIME::Types->new(only_complete => 1));
    $instance->custom_types({});
}

sub default {
    my $instance = shift;
    return Dancer::Config::setting("default_mime_type") || "application/data";
}

sub add_type {
    my ($self, $name, $type) = @_;
    $self->custom_types->{$name} = $type;
    return;
}

sub add_alias {
    my($self, $alias, $orig) = @_;
    my $type = $self->for_name($orig);
    $self->add_type($alias, $type);
    return $type;
}

sub for_file {
    my ($self, $filename) = @_;
    my ($ext) = $filename =~ /\.([^.]+)$/;
    return $self->default unless $ext;
    return $self->for_name($ext);
}

sub name_or_type {
    my($self, $name) = @_;

    return $name if $name =~ m{/};  # probably a mime type
    return $self->for_name($name);
}

sub for_name {
    my ($self, $name) = @_;
    return $self->custom_types->{lc $name} || $self->mime_type->mimeTypeOf(lc $name) || $self->default;
}

42;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dancer::MIME - Singleton object to handle MimeTypes

=head1 VERSION

version 1.3202

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

=head2 for_name

    $mime->for_name( 'jpg' );

Retrieve the mime type for a standard or non standard mime type.

=head2 for_file

    $mime->for_file( 'file.jpg' );

Retrieve the mime type for a file, based on a file extension.

=head2 custom_types

    my $types = $mime->custom_types;

Retrieve the full hash table of added mime types.

=head2 name_or_type

    my $type = $mime->name_or_type($thing);

Resolves the $thing into a content $type whether it's the name of a
MIME type like "txt" or already a mime type like "text/plain".

=head1 AUTHORS

This module has been written and rewritten by different people from
Dancer project.

=head1 LICENCE

This module is released under the same terms as Perl itself.

=head1 SEE ALSO

L<Dancer>

=head1 AUTHOR

Dancer Core Developers

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Alexis Sukrieh.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
