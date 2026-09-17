package Dancer::Serializer::YAML;
#ABSTRACT: serializer for handling YAML data

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

    raise core_serializer => q{Dancer::Serializer::YAML only supports 'YAML' or 'YAML::XS', not $module}
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
    return unless $entity;
    my $module = Dancer::Config::settings->{engines}{YAML}{module} || 'YAML';
    {
        no strict 'refs';
        &{ $module . '::Dump' }($entity);
    }
}

sub deserialize {
    my ($self, $content) = @_;
    my $module = Dancer::Config::settings->{engines}{YAML}{module} || 'YAML';
    return unless $content;

    # Content reaching here is untrusted -- for an app with 'serializer: YAML'
    # (or Serializer::Mutable, which maps both text/x-yaml and text/html to
    # this class) it is the raw request body.
    #
    # YAML tags can ask the loader to build things that are not data.
    # !!perl/hash:Some::Class instantiates an arbitrary blessed object, the
    # entry point for DESTROY/AUTOLOAD gadget chains, and !!perl/code asks for
    # a string eval. Both are refused here.
    #
    # These are set explicitly rather than left to the module's ambient
    # defaults so the behaviour does not depend on which YAML module is
    # configured or the version resolved, and holds even when the surrounding
    # process has set them to something hostile. Both loaders are covered:
    # YAML.pm honours the YAML:: variables, while YAML::XS honours its own
    # YAML::XS:: variables; and a loader that does OR-in an "also allow" flag
    # (YAML::UseCode / YAML::XS::UseCode) is covered too. The two namespaces
    # and the code-loading flags only exist as variables from specific
    # versions -- which is why dist.ini floors YAML at 1.30 and YAML::XS at
    # 0.81 (see the note there).
    no warnings 'once';
    local $YAML::LoadBlessed      = 0;
    local $YAML::LoadCode         = 0;
    local $YAML::UseCode          = 0;
    local $YAML::XS::LoadBlessed  = 0;
    local $YAML::XS::LoadCode     = 0;
    local $YAML::XS::UseCode      = 0;

    {
        no strict 'refs';
        &{ $module . '::Load' }($content);
    }
}

sub content_type {'text/x-yaml'}

1;
__END__

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
