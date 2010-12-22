package Dancer::Object;

# This class is a root class for each object in Dancer.
# It provides basic OO tools for Perl5 without being... Moose ;-)

use strict;
use warnings;
use Carp;

# constructor
sub new {
    my ($class, %args) = @_;
    my $self = \%args;
    bless $self, $class;
    $self->init(%args);
    return $self;
}

sub clone {
    my ($self) = @_;
    croak "The 'Clone' module is needed"
        unless Dancer::ModuleLoader->load('Clone');
    return Clone::clone($self);
}

# initializer
sub init {1}

# meta information about classes
my $_attrs_per_class = {};
sub get_attributes {
    my ($class, $visited_parents) = @_;
    # $visited_parents keeps track of parent classes we already handled, to
    # avoid infinite recursion (in case of dependancies loop). It's not stored as class singleton, otherwise
    # get_attributes wouldn't be re-entrant.
    $visited_parents ||= {};
    my @attributes = @{$_attrs_per_class->{$class} || [] };
    my @parents;
    { no strict 'refs';
      @parents = @{"$class\::ISA"}; }
    foreach my $parent (@parents) {
        # cleanup $parent
        $parent =~ s/'/::/g;
        $parent =~ /^::/
          and $parent = 'main' . $parent;

        # check we didn't visited it already
        $visited_parents->{$parent}++
          and next;

        # check it's a Dancer::Object
        $parent->isa(__PACKAGE__)
          or next;

        # merge parents attributes
        push @attributes, @{$parent->get_attributes($visited_parents)};
    }
    return \@attributes;
}

# accessors builder
sub attributes {
    my ($class, @attributes) = @_;

    # save meta information
    $_attrs_per_class->{$class} = \@attributes;

    # define setters and getters for each attribute
    foreach my $attr (@attributes) {
        my $code = sub {
            my ($self, $value) = @_;
            if (@_ == 1) {
                return $self->{$attr};
            }
            else {
                return $self->{$attr} = $value;
            }
        };
        my $method = "${class}::${attr}";
        { no strict 'refs'; *$method = $code; }
    }
}

1;

__END__

=head1 NAME

Dancer::Object - Objects base class for Dancer

=head1 SYNOPSIS

    package My::Dancer::Extension;

    use strict;
    use warnings;
    use base 'Dancer::Object';

    __PACKAGE__->attributes( qw/name value this that/ );

    sub init {
        # our initialization code, if we need one
    }

=head1 DESCRIPTION

While we B<love> L<Moose>, we can't use it for Dancer and stlil keep Dancer
minimal, so we wrote Dancer::Object instead.

It provides you with attributes and an initializer.

=head1 METHODS

=head2 new

Creates a new object of whatever is based off Dancer::Object. This is a generic
C<new> method so you don't have to write one yourself when extending
C<Dancer::Object>.

It accepts arguments in a hash and runs an additional C<init> method (described
below) which you should implement.

=head2 init

Exists but does nothing. This is so you won't have to write an initializer if
you don't want to.

=head2 clone

Creates and returns a clone of the object using L<Clone>, which is loaded
dynamically. If we cannot load L<Clone>, we throw an exception.

=head2 get_attributes

Get the attributes of the specific class.

=head2 attributes

Generates attributes for whatever object is extending Dancer::Object and saves
them in an internal hashref so they can be later fetched using
C<get_attributes>.

=head1 AUTHOR

Alexis Sukrieh

=head1 LICENSE AND COPYRIGHT

Copyright 2009-2010 Alexis Sukrieh.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

