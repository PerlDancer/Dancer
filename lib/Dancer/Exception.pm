package Dancer::Exception;

use strict;
use warnings;
use Carp;

use base qw(Exporter);

my @exceptions = qw(E_HALTED E_GENERIC);
our @EXPORT_OK = (@exceptions, qw(raise list_exceptions is_dancer_exception));
our %EXPORT_TAGS = ( exceptions => [ @exceptions],
                     utils => => [ qw(raise list_exceptions is_dancer_exception) ],
                     all => \@EXPORT_OK,
                   );

my %custom_exceptions = ();

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
  use Dancer::Exception qw(raise list_exceptions);

  # this does the same thing as above
  use Dancer::Exception qw(:utils);

  # loads all exception names, but not the utils
  use Dancer::Exception qw(:exceptions);

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

Returns a list of strings, the names of available exceptions.

=cut

sub list_exceptions { @exceptions }

=head2 is_dancer_exception

  my $value = is_dancer_exception;

This function tests if an exception is a Dancer one, and if yes
get its value. If not, it returns void

First parameter is the exception to test. Returns the exception value (which is always true), or void (empty list) if the exception was not a dancer exception.

=cut

sub is_dancer_exception {
    ref $_[0] eq __PACKAGE__
      or return;
    return ${$_[0]};
}

=head1 EXCEPTIONS

=head2 E_GENERIC

A generic purpose exception. Not used by internal code, so this exception can
be used by user code safely, without having to create a custom user exception.

=cut

sub E_GENERIC () { 1 }

=head2 E_HALTED

Internal exception, generated when C<halt()> is called (see in L<Dancer> POD).

=cut

sub E_HALTED () { 2 }

=head1 CUSTOM EXCEPTIONS

In addition to internal (and the generic one) exception, users have the ability
to create more Dancer exceptionsfor their need. To do that, use 'create_exception'

=cut

=head2 create_exception


=cut

sub create_custom_exception {
    my ($exception_name) = @_;
    exists $custom_exceptions{$exception_name}
      or die;
}


1;
