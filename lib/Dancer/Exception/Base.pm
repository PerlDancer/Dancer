package Dancer::Exception::Base;

use strict;
use warnings;
use Carp;

use base qw(Exporter);

use overload '""' => sub { $_[0]->message };
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
    my $self = bless {}, $class;
    $self->_raised_arguments(@_);
    return $self;
}

# base class has a passthrough message
sub _message_pattern { '%s' }

sub throw {
    my $self = shift;
    $self->_raised_arguments(@_);
    die $self;
}

sub rethrow { die $_[0] }

sub message {
    my ($self) = @_;
    my $message_pattern = $self->_message_pattern;
    my $message = sprintf($message_pattern, @{$self->_raised_arguments});
    my @composition = (reverse $self->get_composition);
    shift @composition;
    foreach my $component (@composition) {
        my $class = "Dancer::Exception::$component";
        no strict 'refs';
        my $pattern = $class->_message_pattern;
        $message = sprintf($pattern, $message);
    }
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
    my @isa = do { no strict 'refs'; @{"${class}::ISA"}, $class };
    return grep { s|^Dancer::Exception::|| } @isa;
}

sub _raised_arguments {
    my $self = shift;
    @_ and $self->{_raised_arguments} = [ @_ ];
    $self->{_raised_arguments};
}

1;

__END__

=pod

=head1 NAME

Dancer::Exception::Base - the base class of all Dancer exceptions

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

Returns the type or the composed types of an exception.
B<Warning>, the result is a list, so you should call this method in list context.

  try { raise InvalidPassword => 'foo'; }
  catch {
    my ($e) = @_;
    my @list = $e->get_composition()
    # @list contains ( 'InvalidPassword' )
  };
