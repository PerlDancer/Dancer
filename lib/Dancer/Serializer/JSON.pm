package Dancer::Serializer::JSON;
our $AUTHORITY = 'cpan:SUKRIA';
#ABSTRACT: serializer for handling JSON data
$Dancer::Serializer::JSON::VERSION = '1.3202';
use strict;
use warnings;
use Carp;
use Dancer::ModuleLoader;
use Dancer::Deprecation;
use Dancer::Config 'setting';
use Dancer::Exception qw(:all);
use base 'Dancer::Serializer::Abstract';


# helpers

sub from_json {
    my $s = Dancer::Serializer::JSON->new;
    $s->deserialize(@_);
}

sub to_json {
    my $s = Dancer::Serializer::JSON->new;
    $s->serialize(@_);
}

# class definition

sub loaded { Dancer::ModuleLoader->load_with_params('JSON', '-support_by_pp') }

sub init {
    my ($self) = @_;
    raise core_serializer => 'JSON is needed and is not installed'
      unless $self->loaded;
}

sub serialize {
    my $self   = shift;
    my $entity = shift;

    my $options = $self->_serialize_options_as_hashref(@_) || {};

    my $config = setting('engines') || {};
    $config = $config->{JSON} || {};

    # straight pass through of config options to JSON
    map { $options->{$_} = $config->{$_} } keys %$config;

    # pull in config from serializer init as well (and possibly override settings from the conf file)
    map { $options->{$_} = $self->config->{$_} } keys %{$self->config};

    if (setting('environment') eq 'development' and not defined $options->{pretty}) {
        $options->{pretty} = 1;
    }

    JSON::to_json( $entity, $options );
}

sub deserialize {
    my $self   = shift;
    my $entity = shift;

    my $options = $self->_deserialize_options_as_hashref(@_);
    JSON::from_json( $entity, $options );
}

# Standard JSON behaviour is fine when serializing; we'll end up
# encoding as UTF8 later on.
sub _serialize_options_as_hashref {
    return shift->_options_as_hashref(@_);
}

# JSON should be UTF8 by default, so explicitly decode it as such
# on its way in.
sub _deserialize_options_as_hashref {
    my $self = shift;
    my $options = $self->_options_as_hashref(@_) || {};
    $options->{utf8} = 1 if !exists $options->{utf8};
    return $options;
}

sub _options_as_hashref {
    my $self = shift;

    return if scalar @_ == 0;

    if ( scalar @_ == 1 ) {
        return shift;
    }
    elsif ( scalar @_ % 2 ) {
        carp "options for to_json/from_json must be key value pairs (as a hashref)";
    }
    else {
        Dancer::Deprecation->deprecated(
            version => '1.3002',
            fatal => 1,
            message => 'options as hash for to_json/from_json is DEPRECATED. please pass a hashref',
        );
    }
}

sub content_type {'application/json'}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dancer::Serializer::JSON - serializer for handling JSON data

=head1 VERSION

version 1.3202

=head1 SYNOPSIS

=head1 DESCRIPTION

This class is an interface between Dancer's serializer engine abstraction layer
and the L<JSON> module.

In order to use this engine, use the template setting:

    serializer: JSON

This can be done in your config.yml file or directly in your app code with the
B<set> keyword. This serializer will also be used when the serializer is set
to B<mutable> and the correct Accept headers are supplied.

The L<JSON> module will pass configuration variables straight through.
Some of these can be useful when debugging/developing your app: B<pretty> and
B<canonical>, and others useful with ORMs like L<DBIx::Class>: B<allow_blessed>
and B<convert_blessed>.  Please consult the L<JSON> documentation for more
information and a full list of configuration settings. You can add extra
settings to the B<engines> configuration to turn these on. For example:

    engines:
        JSON:
            allow_blessed:   '1'
            canonical:       '1'
            convert_blessed: '1'

=head1 METHODS

=head2 serialize

Serialize a data structure to a JSON structure.

=head2 deserialize

Deserialize a JSON structure to a data structure

=head2 content_type

Return 'application/json'

=head1 AUTHOR

Dancer Core Developers

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Alexis Sukrieh.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
