package Dancer::Object::Singleton;
our $AUTHORITY = 'cpan:SUKRIA';
#ABSTRACT: Singleton base class for Dancer
$Dancer::Object::Singleton::VERSION = '1.3202';
# This class is a root class for singleton objects in Dancer.
# It provides basic OO singleton tools for Perl5 without being... MooseX::Singleton ;-)

use strict;
use warnings;
use Carp;
use Dancer::Exception qw(:all);

use base qw(Dancer::Object);

# pool of instances (only one per package name)
my %instances;

# constructor
sub new {
    my ($class) = @_;
    raise core => "you can't call 'new' on $class, as it's a singleton. Try to call 'instance'";
}

sub clone {
    my ($class) = @_;
    raise core => "you can't call 'clone' on $class, as it's a singleton. Try to call 'instance'";
}

sub instance {
    my ($class) = @_;
    my $instance = $instances{$class};

    # if exists already
    defined $instance
      and return $instance;

    # create the instance
    $instance = bless {}, $class;
    $class->init($instance);

    # save and return it
    $instances{$class} = $instance;
    return $instance;
}

# accessor code for singleton objects
# (overloaded from Dancer::Object)
sub _setter_code {
    my ($class, $attr) = @_;
    sub {
        my ($class_or_instance, $value) = @_;
        my $instance = ref $class_or_instance ?
          $class_or_instance : $class_or_instance->instance;
        if (@_ == 1) {
            return $instance->{$attr};
        }
        else {
            return $instance->{$attr} = $value;
        }
    };
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dancer::Object::Singleton - Singleton base class for Dancer

=head1 VERSION

version 1.3202

=head1 SYNOPSIS

    package My::Dancer::Extension;

    use strict;
    use warnings;
    use base 'Dancer::Object::Singleton';

    __PACKAGE__->attributes( qw/name value this that/ );

    sub init {
        my ($class, $instance) = @_;
        # our initialization code, if we need one
    }

    # .. later on ..

    # returns the unique instance
    my $singleton_intance = My::Dancer::Extension->instance();

=head1 DESCRIPTION

Dancer::Object::Singleton is meant to be used instead of Dancer::Object, if you
want your object to be a singleton, that is, a class that has only one instance
in the application.

It provides you with attributes and an initializer.

=head1 METHODS

=head2 instance

Returns the instance of the singleton. The instance is created only when
needed. The creation will call the C<init()> method, which you should implement.

=head2 init

Exists but does nothing. This is so you won't have to write an initializer if
you don't want to. init receives the instance as argument.

=head2 get_attributes

Get the attributes of the specific class.

=head2 attributes

Generates attributes for whatever object is extending Dancer::Object and saves
them in an internal hashref so they can be later fetched using
C<get_attributes>.

=head1 AUTHOR

Dancer Core Developers

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Alexis Sukrieh.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
