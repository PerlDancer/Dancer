package Dancer::Serializer::YAML;
our $AUTHORITY = 'cpan:SUKRIA';
#ABSTRACT: serializer for handling YAML data
$Dancer::Serializer::YAML::VERSION = '1.3202';
use strict;
use warnings;
use Carp;
use Dancer::ModuleLoader;
use Dancer::Config;
use Dancer::Exception qw(:all);
use base 'Dancer::Serializer::Abstract';

# helpers

sub from_yaml {
    my ($yaml) = @_;
    my $s = Dancer::Serializer::YAML->new;
    $s->deserialize($yaml);
}

sub to_yaml {
    my ($data) = @_;
    my $s = Dancer::Serializer::YAML->new;
    $s->serialize($data);
}

# class definition

sub loaded { 
    my $module = Dancer::Config::settings->{engines}{YAML}{module} || 'YAML';

    raise core_serializer => q{Dancer::Serializer::YAML only support 'YAML' or 'YAML::XS', not $module}
        unless $module =~ /^YAML(?:::XS)?$/;

    Dancer::ModuleLoader->load($module) 
        or raise core_serializer => "$module is needed and is not installed";
}

sub init {
    my ($self) = @_;
    $self->loaded;
}

sub serialize {
    my ($self, $entity) = @_;
    YAML::Dump($entity);
}

sub deserialize {
    my ($self, $content) = @_;
    YAML::Load($content);
}

sub content_type {'text/x-yaml'}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dancer::Serializer::YAML - serializer for handling YAML data

=head1 VERSION

version 1.3202

=head1 SYNOPSIS

=head1 DESCRIPTION

This class is an interface between Dancer's serializer engine abstraction layer
and the L<YAML> (or L<YAML::XS>) module.

In order to use this engine, use the template setting:

    serializer: YAML

This can be done in your config.yml file or directly in your app code with the
B<set> keyword. This serializer will also be used when the serializer is set
to B<mutable> and the correct Accept headers are supplied.

By default, the module L<YAML> will be used to serialize/deserialize data and
the application configuration files. This can be changed via the
configuration:

    engines:
        YAML:
            module: YAML::XS

Note that if you want all configuration files to be read using C<YAML::XS>, 
that configuration has to be set via application code:

   config->{engines}{YAML}{module} = 'YAML::XS';

=head1 METHODS

=head2 serialize

Serialize a data structure to a YAML structure.

=head2 deserialize

Deserialize a YAML structure to a data structure

=head2 content_type

Return 'text/x-yaml'

=head1 AUTHOR

Dancer Core Developers

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Alexis Sukrieh.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
