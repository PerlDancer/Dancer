package Dancer::Exception;

use strict;
use warnings;
use Carp;

use base qw(Exporter);

my @exceptions = qw(E_HALTED E_GENERIC);
our @EXPORT_OK = (@exceptions, qw(raise list_exceptions is_dancer_exception register_custom_exception));
our %value_to_custom_name;
our %custom_name_to_value;
our %EXPORT_TAGS = ( exceptions => [ @exceptions],
                     internal_exceptions => [ @exceptions],
                     custom_exceptions => [],
                     utils => => [ qw(raise list_exceptions is_dancer_exception register_custom_exception) ],
                     all => \@EXPORT_OK,
                   );


=head1 SYNOPSIS

  use Dancer::Exception qw(:all);

  # raise an exception
  raise E_HALTED;

  # get a list of possible exceptions
  my @exception_names = list_exceptions;

  # catch an exception
  eval { ... };
  if ( my $value = is_dancer_exception(my $exception = $@) ) {
    if ($value == ( E_HALTED | E_FOO ) ) {
        # it's a halt or foo exception...
    }
  } elsif ($exception) {
    # do something with $exception (don't use $@ as it may have been reset)
  }

=head1 DESCRIPTION

This is a lighweight exceptions module. Yes, it's not Object Oriented, that's
on purpose, to keep it light and fast. Thus, you can use ref() instead of
->isa(), and exceptions have no method to call on. Simply dereference them to
get their value

An exception is a blessed reference on an integer. This integer is always a
power of two, so that you can test its value using the C<|> operator. A Dancer
exception is always blessed as C<'Dancer::Exception'>.

=head1 EXPORTS

to be able to use this module, you should use it with these options :

  # loads specific exceptions only. See list_exceptions for a list
  use Dancer::Exception qw(E_HALTED E_PLOP);

  # loads the utility functions
  use Dancer::Exception qw(raise list_exceptions is_dancer_exception register_custom_exception);

  # this does the same thing as above
  use Dancer::Exception qw(:utils);

  # loads all exception names, but not the utils
  use Dancer::Exception qw(:exceptions);

  # loads only the internal exception names
  use Dancer::Exception qw(:internal_exceptions);

  # loads only the custom exception names
  use Dancer::Exception qw(:custom_exceptions);

  # loads everything
  use Dancer::Exception qw(:all);

=head1 FUNCTIONS

=head2 raise

  raise E_HALTED;

Used to raise an exception. Takes in argument an integer (must be a power of
2). You should give it an existing Dancer exception.

=cut

# yes we use __CLASS__, it's not OO and inheritance proof, but if you'd pay
# attention, you'd have noticed that this module is *not* a class :)
sub raise { die bless \ do { my $e = $_[0] }, __PACKAGE__ }

=head2 list_exceptions

  my @exception_names = list_exceptions;
  my @exception_names = list_exceptions(type => 'internal');
  my @exception_names = list_exceptions(type => 'custom');

Returns a list of strings, the names of available exceptions.

Parameters are an optional list of key values. Accepted keys are for now only
C<type>, to restrict the list of exceptions on the type of the Dancer
exception. C<type> can be 'internal' or 'custom'.

=cut

sub list_exceptions {
    my %params = @_;
    ( $params{type} || '' ) eq 'internal'
      and return @exceptions;
    ( $params{type} || '' ) eq 'custom'
      and return keys %custom_name_to_value;
    return @exceptions, keys %custom_name_to_value;
}

=head2 is_dancer_internal_exception

  # test if it's a Dancer exception
  my $value = is_dancer_exception($@);
  # test if it's a Dancer internal exception
  my $value = is_dancer_exception($@, type => 'internal');
  # test if it's a Dancer custom exception
  my $value = is_dancer_exception($@, type => 'custom');

This function tests if an exception is a Dancer exception, and if yes get its
value. If not, it returns void

First parameter is the exception to test. Other parameters are an optional list
of key values. Accepted keys are for now only C<type>, to restrict the test on
the type of the Dancer exception. C<type> can be 'internal' or 'custom'.

Returns the exception value (which is always true), or void (empty list) if the
exception was not a dancer exception (of the right type if specified).

=cut

sub is_dancer_exception {
    my ($exception, %params) = @_;
    ref $exception eq __PACKAGE__
      or return 0;
    my $value = $$exception;
    @_ > 1
      or return $value;
    $params{type} eq 'internal' && $value < 2**16
      and return $value;
    $params{type} eq 'custom' && $value >= 2**16
      and return $value;
    return 0;
}

=head2 register_custom_exception

  register_custom_exception('E_FROBNICATOR');
  # now I can use this exception for raising
  raise E_FROBNICATOR;


=cut

sub register_custom_exception {
    my ($exception_name, %params) = @_;
    exists $value_to_custom_name{$exception_name}
      and croak "can't register '$exception_name' custom exception, it already exists";
    keys %value_to_custom_name < 16
      or croak "can't register '$exception_name' custom exception, all 16 custom slots are registered";
    my $value = 2**16;
    while($value_to_custom_name{$value}) { $value*=2; }
    $value_to_custom_name{$value} = $exception_name;
    $custom_name_to_value{$exception_name} = $value;

    my $pkg = __PACKAGE__;
    no strict 'refs';
    *{"$pkg\::$exception_name"} = sub { $value };

    push @EXPORT_OK, $exception_name;
    push @{$EXPORT_TAGS{custom_exceptions}}, $exception_name;
    $params{no_import}
      or $pkg->export_to_level(1, $pkg, $exception_name);

    return;
}


=head1 INTERNAL EXCEPTIONS

=head2 E_GENERIC

A generic purpose exception. Not used by internal code, so this exception can
be used by user code safely, without having to register a custom user exception.

=cut

sub E_GENERIC () { 1 }

=head2 E_HALTED

Internal exception, generated when C<halt()> is called (see in L<Dancer> POD).

=cut

sub E_HALTED () { 2 }

=head1 CUSTOM EXCEPTIONS

In addition to internal (and the generic one) exception, users have the ability
to register more Dancer exceptions for their need. To do that, see
C<register_custom_exception>.

=cut

1;
