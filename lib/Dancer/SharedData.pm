package Dancer::SharedData;
# ABSTRACT: Dancer shared data

=head1 DESCRIPTION

Manages global/shared data for all classes.

=cut
use strict;
use warnings;
use Dancer::Timer;
use Dancer::Response;

my $_vars     = {};    # shared variables
my $_headers  = undef; # request headers
my $_request  = undef; # request singleton
my $_response = undef; # current response
my $_timer    = undef; # request timer

=method vars

Returns a hash reference to the shared C<vars>.

=cut
sub vars {$_vars}

=method var

This accessor sets (or queries) a variable from the shared data variables table.

  my $value = Dancer::SharedData->var( 'foo' );

  Daner::SharedData->var( bar => 'baz' );

=cut
sub var {
    my ($class, $key, $value) = @_;
    $_vars->{$key} = $value if (@_ == 3);
    return $_vars->{$key};
}


=method headers

If used with one argument sets the current shared headers.

If called without arguments returns the current shared headers or
undef if none is present.

=cut
sub headers { (@_ == 2) ? $_headers = $_[1] : $_headers }

=method request

If used with one argument sets the current shared request.

If called without arguments returns the current shared request or
undef if none is present.

=cut
sub request { (@_ == 2) ? $_request = $_[1] : $_request }

=method response

If used with one argument sets the current shared response to the
supplied one:

  Dancer::SharedData->response( $my_response );

If called without arguments returns the current shared response, or
creates a new one if none is available.

=cut
sub response {
    if (@_ == 2) {
        $_response = $_[1];
    }else{
        $_response = Dancer::Response->new() if !defined $_response;
        return $_response;
    }
}

=method reset_response

Resets the current shared response.

=cut
sub reset_response { $_response = undef }

=method timer

Returns the shared L<Dancer::Timer> object or creates a new one if
none exists at the moment.

=cut
sub timer { $_timer ||= Dancer::Timer->new }

=method reset_timer

Resets shared data timer.

=cut
sub reset_timer { $_timer = Dancer::Timer->new }

=method reset_all

Clears all shared data variables.

=cut
sub reset_all {
    $_vars = {};
    undef $_request;
    undef $_headers;
    reset_timer();
    reset_response();
}

'Dancer::SharedData';
