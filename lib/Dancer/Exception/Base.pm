package Dancer::Exception::Base;
our $AUTHORITY = 'cpan:SUKRIA';
#ABSTRACT: the base class of all Dancer exceptions
$Dancer::Exception::Base::VERSION = '1.3202';
use strict;
use warnings;
use Carp;

use base qw(Exporter);

use Dancer::Exception;

use overload '""' => sub {
    my ($self) = @_;
    $self->message
      . ( $Dancer::Exception::Verbose ? $self->{_longmess} : $self->{_shortmess});
};

# string comparison is done without the stack traces
use overload 'cmp' => sub {
    my ($e, $f) = @_;
    ( ref $e && $e->isa(__PACKAGE__)
      ? $e->message : $e )
      cmp
    ( ref $f && $f->isa(__PACKAGE__)
      ? $f->message : $f )
};

# This is the base class of all exceptions

sub new {
    my $class = shift;
    my $self = bless { _raised_arguments => [],
                       _shortmess => '',
                       _longmess => '',
                     }, $class;
    $self->_raised_arguments(@_);
    return $self;
}

# base class has a passthrough message
sub _message_pattern { '%s' }

sub throw {
    my $self = shift;
    $self->_raised_arguments(@_);
    local $Carp::CarpInternal;
    local $Carp::Internal;
    $Carp::Internal{'Dancer'} ++;
    $Carp::CarpInternal{'Dancer::Exception'} ++;
    $self->{_shortmess} = Carp::shortmess;
    $self->{_longmess} = Carp::longmess;
    die $self;
}

sub rethrow { die $_[0] }

sub message {
    my ($self) = @_;
    my $message_pattern = $self->_message_pattern;
    my $message = sprintf($message_pattern, @{$self->_raised_arguments});
    return $message;
}

sub does {
    my $self = shift;
    my $regexp = join('|', map { '^' . $_ . '$'; } @_);
    (scalar grep { /$regexp/ } $self->get_composition) >= 1;
}

sub get_composition {
    my ($self) = @_;
    my $class = ref($self);

    my ($_recurse_isa, %seen);
    $_recurse_isa = sub {
        my ($class) = @_;
        $seen{$class}++
          and return;

        no strict 'refs';
        return $class, map { $_recurse_isa->($_) }
                      grep { /^Dancer::Exception::/ }
                          @{"${class}::ISA"};
        
    };
    grep { s/^Dancer::Exception::// } $_recurse_isa->($class);
}

sub _raised_arguments {
    my $self = shift;
    @_ and $self->{_raised_arguments} = [ @_ ];
    $self->{_raised_arguments};
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dancer::Exception::Base - the base class of all Dancer exceptions

=head1 VERSION

version 1.3202

=head1 DESCRIPTION

Dancer::Exception::Base is the base class of all Dancer exception. All core
exceptions, and all custom exception registered using
C<Dancer::Exception::register_exception> inherits of
C<Dancer::Exception::Base>.

=head1 METHODS

=head2 throw

Throws an exception. It's what C<raise> (from L<Dancer::Exception>) uses. Any
arguments is set as raising parameters. You should not use this method
directly, but instead, use C<raise> from L<Dancer::Exception>.

B<Warning>, if you want to rethrow an exception, use C<rethrow>.

=head2 rethrow

Re-throw the exception, without touching its parameters. Useful if you've
caught and exception but don't want to handle it, and want to rethrow it.

  try { ... }
  catch {
    my ($e) = @_;
    $e->does('InvalidLogin')
      or $e->rethrow;
    ...
  };

=head2 does

Given an exception type, returns true if the exception is of the same type.

  try { raise InvalidLogin => 'foo'; }
  catch {
    my ($e) = @_;
    $e->does('InvalidLogin') # true
    ...
  };

It can receive more than one type, useful for composed exception, or checking
multiple types at once. C<does> performs a logical OR between them:

  try { raise InvalidPassword => 'foo'; }
  catch {
    my ($e) = @_;
    $e->does('InvalidLogin', 'InvalidPassword') # true
    ...
  };

=head2 get_composition

Returns the composed types of an exception. As every exception inherits of
Dancer::Exception::Base, the returned list contains at least 'Base', and the
exception class name.

B<Warning>, the result is a list, so you should call this method in list context.

  try { raise InvalidPassword => 'foo'; }
  catch {
    my ($e) = @_;
    my @list = $e->get_composition()
    # @list contains ( 'InvalidPassword', 'Base', ... )
  };

=head2 message

Computes and returns the message associated to the exception. It'll apply the
parameters that were set at throw time to the message pattern of the exception.

=head1 STRINGIFICATION

=head2 string overloading

All Dancer exceptions properly stringify. When evaluated to a string, they
return their message, concatenated with their stack trace (see below).

=head2 cmp overloading

The C<cmp> operator is also overloaded, thus all the string operations can be
done on Dancer's exceptions, as they will all be based on the overloaded C<cmp>
operator. Dancer exceptions will be compared B<without> their stacktraces.

=head1 STACKTRACE

Similarly to L<Carp>, Dancer exceptions stringification appends a string
stacktrace to the exception message.

The stacktrace can be a short one, or a long one. Actually the implementation
internally uses L<Carp>.

To enable long stack trace (for debugging purpose), you can use the global
variable C<Dancer::Exception::Verbose> (see below).

The short and long stacktrace snippets are stored within C<$self->{_shortmess}>
and C<$self->{_longmess}>. Don't touch them or rely on them, they are
internals, and will change soon.

=head1 GLOBAL VARIABLE

=head2 $Dancer::Exception::Verbose

When set to 1, exceptions will stringify with a long stack trace. This variable
is similar to C<$Carp::Verbose>. I recommend you use it like that:

  local $Dancer::Exception::Verbose;
  $Dancer::Exception::Verbose = 1;

All the L<Carp> global variables can also be used to alter the stacktrace
generation.

=head1 AUTHOR

Dancer Core Developers

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Alexis Sukrieh.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
