package Dancer::Exception;
our $AUTHORITY = 'cpan:SUKRIA';
#ABSTRACT: class for throwing and catching exceptions
$Dancer::Exception::VERSION = '1.3202';
use strict;
use warnings;
use Carp;
use Scalar::Util qw(blessed);

our $Verbose = 0;

use Dancer::Exception::Base;

use base qw(Exporter);

our @EXPORT_OK = (qw(try catch continuation register_exception registered_exceptions raise));
our %EXPORT_TAGS = ( all => \@EXPORT_OK );

use Try::Tiny ();

sub try (&;@) {
    goto &Try::Tiny::try;
}

sub catch (&;@) {
	my ( $block, @rest ) = @_;

    my $continuation_code;
    my @new_rest = grep { ref ne 'Try::Tiny::Catch' or $continuation_code = $$_, 0 } @rest;
    $continuation_code
      and return ( bless( \ sub {
          ref && blessed($_) && $_->isa('Dancer::Continuation')
            ? $continuation_code->(@_) : $block->(@_);
      },  'Try::Tiny::Catch') , @new_rest);

    return ( bless ( \ sub {
          ref && blessed($_) && $_->isa('Dancer::Continuation')
            ? die($_) : $block->(@_) ;
      }, 'Try::Tiny::Catch'), @new_rest );
}

sub continuation (&;@) {
	my ( $block, @rest ) = @_;

    my $catch_code;
    my @new_rest = grep { ref ne 'Try::Tiny::Catch' or $catch_code = $$_, 0 } @rest;
    $catch_code 
      and return ( bless( \ sub {
          ref && blessed($_) && $_->isa('Dancer::Continuation')
            ? $block->(@_) : $catch_code->(@_);
      },  'Try::Tiny::Catch') , @new_rest);

    return ( bless ( \ sub {
          ref && blessed($_) && $_->isa('Dancer::Continuation')
            ? $block->(@_) : die($_);
      }, 'Try::Tiny::Catch'), @new_rest );
}

sub raise ($;@) {
    my $exception_name = shift;
    my $exception;
    if ($exception_name =~ s/^\+//) {
        $exception = $exception_name->new(@_);
    } else {
        _camelize($exception_name);
        $exception = "Dancer::Exception::$exception_name"->new(@_);
    }
    $exception->throw();
}

sub _camelize {
    # using aliasing for ease of use
    $_[0] =~ s/^(.)/uc($1)/e;
    $_[0] =~ s/_(.)/'::' . uc($1)/eg;    
}

sub register_exception {
    my ($exception_name, %params) = @_;
    my $exception_class = 'Dancer::Exception::' . $exception_name;
    my $path = $exception_class; $path =~ s|::|/|g; $path .= '.pm';

    if (exists $INC{$path}) {
        local $Carp::CarpLevel = $Carp::CarpLevel++;
        'Dancer::Exception::Base::Internal'
            ->new("register_exception failed: $exception_name is already defined")
            ->throw;
    }

    my $message_pattern = $params{message_pattern};
    my $composed_from = $params{composed_from};
    my @composition = map { 'Dancer::Exception::' . $_ } @$composed_from;

    $INC{$path} = __FILE__;
    eval "\@${exception_class}::ISA=qw(Dancer::Exception::Base " . join (' ', @composition) . ');';

    if (defined $message_pattern) {
        no strict 'refs';
        *{"${exception_class}::_message_pattern"} = sub { $message_pattern };
    }

}

sub registered_exceptions {
    sort map { s|/|::|g; s/\.pm$//; $_ } grep { s|^Dancer/Exception/||; } keys %INC;
}

register_exception(@$_) foreach (
    [ 'Core',                message_pattern => 'core - %s' ],
    [ 'Core::App',           message_pattern => 'core - app - %s',         composed_from => [ qw(Core) ] ],
    [ 'Core::Config',        message_pattern => 'core - config - %s',      composed_from => [ qw(Core) ] ],
    [ 'Core::Deprecation',   message_pattern => 'core - deprecation - %s', composed_from => [ qw(Core) ] ],
    [ 'Core::Engine',        message_pattern => 'core - engine - %s',      composed_from => [ qw(Core) ] ],
    [ 'Core::Factory',       message_pattern => 'core - factory - %s',     composed_from => [ qw(Core) ] ],
    [ 'Core::Factory::Hook', message_pattern => 'core - hook - %s',        composed_from => [ qw(Core::Factory) ] ],
    [ 'Core::Hook',          message_pattern => 'core - hook - %s',        composed_from => [ qw(Core) ] ],
    [ 'Core::Fileutils',     message_pattern => 'core - file utils - %s',  composed_from => [ qw(Core) ] ],
    [ 'Core::Handler',       message_pattern => 'core - handler - %s',     composed_from => [ qw(Core) ] ],
    [ 'Core::Handler::PSGI', message_pattern => 'core - handler - %s',     composed_from => [ qw(Core::Handler) ] ],
    [ 'Core::Plugin',        message_pattern => 'core - plugin - %s',      composed_from => [ qw(Core) ] ],
    [ 'Core::Renderer',      message_pattern => 'core - renderer - %s',    composed_from => [ qw(Core) ] ],
    [ 'Core::Request',       message_pattern => 'core - request - %s',     composed_from => [ qw(Core) ] ],
    [ 'Core::Route',         message_pattern => 'core - route - %s',       composed_from => [ qw(Core) ] ],
    [ 'Core::Serializer',    message_pattern => 'core - serializer - %s',  composed_from => [ qw(Core) ] ],
    [ 'Core::Template',      message_pattern => 'core - template - %s',    composed_from => [ qw(Core) ] ],
    [ 'Core::Session',       message_pattern => 'core - session - %s',     composed_from => [ qw(Core) ] ],
);

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dancer::Exception - class for throwing and catching exceptions

=head1 VERSION

version 1.3202

=head1 SYNOPSIS

    use Dancer::Exception qw(:all);

    register_exception('DataProblem',
                        message_pattern => "test message : %s"
                      );

    sub do_stuff {
      raise DataProblem => "we've lost data!";
    }

    try {
      do_stuff()
    } catch {
      # an exception was thrown
      my ($exception) = @_;
      if ($exception->does('DataProblem')) {
        # handle the data problem
        my $message = $exception->message();
      } else {
        $exception->rethrow
      }
    };

=head1 DESCRIPTION

Dancer::Exception is based on L<Try::Tiny>. You can try and catch exceptions,
like in L<Try::Tiny>.

Exceptions are objects, from subclasses of L<Dancer::Exception::Base>.

However, for internal Dancer usage, we introduce a special class of exceptions,
called L<Dancer::Continuation>. Exceptions that are from this class are not
caught with a C<catch> block, but only with a C<continuation>. That's a cheap
way to implement a I<workflow interruption>. Dancer users should ignore this
feature.

=head2 What it means for Dancer users

Users can throw and catch exceptions, using C<try> and C<catch>. They can reuse
some Dancer core exceptions (C<Dancer::Exception::Base::*>), but they can also
create new exception classes, and use them for their own means. That way it's
easy to use custom exceptions in a Dancer application. Have a look at
C<register_exception>, C<raise>, and the methods in L<Dancer::Exception::Base>.

=head1 METHODS

=head2 try

Same as in L<Try::Tiny>

=head2 catch

Same as in L<Try::Tiny>. The exception can be retrieved as the first parameter:

    try { ... } catch { my ($exception) = @_; };

=head2 continuation

To be used by Dancer developers only, in Dancer core code.

=head2 raise

  # raise Dancer::Exception::Base::Custom
  raise Custom => "user $username is unknown";

  # raise Dancer::Exception::Base::Custom::Frontend
  raise 'Custom::Frontend' => "user $username is unknown";

  # same, raise Dancer::Exception::Base::Custom::Frontend
  raise custom_frontend => "user $username is unknown";

  # raise My::Own::ExceptionSystem::Invalid::Login
  raise '+My::Own::ExceptionSystem::Invalid::Login' => "user $username is unknown";

raise provides an easy way to throw an exception. First parameter is the name
of the exception class, without the C<Dancer::Exception::> prefix. other
parameters are stored as I<raising arguments> in the exception. Usually the
parameters is an exception message, but it's left to the exception class
implementation.

If the exception class name starts with a C<+>, then the
C<Dancer::Exception::> won't be added. This allows one to build their own
exception class hierarchy, but you should first look at C<register_exception>
before implementing your own class hierarchy. If you really wish to build your
own exception class hierarchy, we recommend that all exceptions inherit of
L<Dancer::Exception::>. Or at least it should implement its methods.

The exception class can also be written as words separated by underscores, it'll be
camelized automatically. So C<'Exception::Foo'> and C<'exception_foo'> are
equivalent. Be careful, C<'MyException'> can't be written C<'myexception'>, as
it would be camelized into C<'Myexception'>.

=head2 register_exception

This method allows one to register custom exceptions, usable by Dancer users in
their route code (actually pretty much everywhere).

  # simple exception
  register_exception ('InvalidCredentials',
                      message_pattern => "invalid credentials : %s",
                     );

This registers a new custom exception. To use it, do:

  raise InvalidCredentials => "user Herbert not found";

The exception message can be retrieved with the C<$exception-E<gt>message> method, and we'll be
C<"invalid credentials : user Herbert not found"> (see methods in L<Dancer::Exception::Base>)

  # complex exception
  register_exception ('InvalidLogin',
                      composed_from => [qw(Fatal InvalidCredentials)],
                      message_pattern => "wrong login or password",
                   );

In this example, the C<InvalidLogin> is built as a composition of the C<Fatal>
and C<InvalidCredentials> exceptions. See the C<does> method in
L<Dancer::Exception::Base>.

=head2 registered_exceptions

  my @exception_classes = registered_exceptions;

Returns the list of exception class names. It will list core exceptions C<and>
custom exceptions (except the one you've registered with a leading C<+>, see
C<register_exception>). The list is sorted.

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
