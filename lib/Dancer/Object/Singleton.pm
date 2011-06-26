package Dancer::Object::Singleton;
# ABSTRACT: Singleton base class for Dancer
use strict;
use warnings;
use Carp;

=method attributes

Generates attributes for whatever object is extending Dancer::Object
and saves them in an internal hashref so they can be later fetched
using C<get_attributes>.

=method get_attributes

Get the attributes of the specific class.

=method init

Exists but does nothing. This is so you won't have to write an
initializer if you don't want to. init receives the instance as
argument.

=cut


use base qw(Dancer::Object);

# pool of instances (only one per package name)
my %instances;

=method new

The method C<new> does not exist for singletons. Its implementation
exists just to warn the user that the operation is not possible.

=cut

sub new {
    my ($class) = @_;
    croak "you can't call 'new' on $class, as it's a singleton. Try to call 'instance'";
}

=method clone

The method C<clone> does not exist for singletons. Its implementation
exists just to warn the user that the operation is not possible.

=cut

sub clone {
    my ($class) = @_;
    croak "you can't call 'clone' on $class, as it's a singleton. Try to call 'instance'";
}


=method instance

Returns the instance of the singleton. The instance is created only
when needed. The creation will call the C<init()> method, which you
should implement.

=cut

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


# private

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

Dancer::Object::Singleton is meant to be used instead of
L<Dancer::Object>, if you want your object to be a singleton, that is,
a class that has only one instance in the application.

It provides you with attributes and an initializer.

=cut

