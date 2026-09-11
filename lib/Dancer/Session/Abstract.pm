package Dancer::Session::Abstract;
#ABSTRACT: abstract class for session engine

use strict;
use warnings;
use Carp;

use base 'Dancer::Engine';

use Crypt::URandom ();
use MIME::Base64 'encode_base64url';

use Dancer::Config 'setting';
use Dancer::Cookies;

__PACKAGE__->attributes('id');

# args: ($class, $id)
# receives a session id and should return a session object if found, or undef
# otherwise.
sub retrieve {
    confess "retrieve not implemented";
}

# args: ($class)
# create a new empty session, flush it and return it.
sub create {
    confess "create not implemented";
}

# args: ($self)
# write the (serialized) current session to the session storage
sub flush {
    confess "flush not implemented";
}

# args: ($self)
# remove the session from the session storage
sub destroy {
    confess "destroy not implemented";
}

# does nothing in most cases (exception is YAML)
sub reset {
    return;
}

# if subclass overrides to true, flush will not be called after write
# and subclass or application must call flush (perhaps in an after hook)
sub is_lazy { 0 };

# This is the default constructor for the session object, the only mandatory
# attribute is 'id'. The whole object should be serialized by the session
# engine.
# If you override this constructor, remember to call $self->SUPER::init() so
# that the session ID is still generated.
sub init {
    my ($self) = @_;
    if (!$self->id) {
        $self->id(build_id());
    }
}

# this method can be overwritten in any Dancer::Session::* module
sub session_name {
    setting('session_name') || 'dancer.session';
}

# May be overriden if session key value pairs aren't stored in the
# session object's hash
sub get_value {
    my ( $self, $key ) = @_;
    return $self->{$key};
}

# May be overriden if session key value pairs aren't stored in the
# session object's hash
sub set_value {
    my ( $self, $key, $value ) = @_;
    $self->{$key} = $value;
}


# Methods below this line should not be overloaded.

# Build a cryptographically-strong session ID. The 4-byte big-endian
# timestamp prefix keeps IDs roughly monotonic (which cleanup scripts
# rely on); the 20 bytes of OS randomness give 160 bits of entropy. The
# combined 24 bytes base64url-encode to 32 characters.
sub build_id {
    return encode_base64url(
        pack( "Na*", time, Crypt::URandom::urandom(20) )
    );
}

sub read_session_id {
    my ($class) = @_;

    my $name = $class->session_name();
    my $c    = Dancer::Cookies->cookies->{$name};
    return unless defined $c;
    if ($class->validate_session_id($c->value)) {
        return $c->value;
    } else {
        warn "Rejecting invalid session ID ". $c->value;
        return;
    }
}

# Validate session ID (base64url chars plus hyphen and tilde by default) to
# avoid potential issues, e.g. if the ID is used insecurely elsewhere.  The
# 4096-character upper limit corresponds to the maximum size of an HTTP cookie
# (RFC 6265 / browser limit), which accommodates cookie-based session engines
# such as Dancer::Session::Cookie while rejecting oversized values that would
# otherwise be handed to the backend unchanged.  If a session provider expects
# more unusual IDs, it can override this class method with one that validates
# according to that provider's expectation of how a session ID should look.
sub validate_session_id {
    my ($class, $id) = @_;

    return 0
      if !defined $id || length($id) > 4096;

    return $id =~ m/\A[A-Za-z0-9_\-~]+\z/;
}

sub write_session_id {
    my ($class, $id) = @_;

    my $name = $class->session_name();

    # If we've already pushed the appropriate cookie to the response, then we
    # don't need to do any more
    if (my $cookie = Dancer::Cookies->cookie($name)) {
        if ($cookie eq $id) {
            return;
        }
    }

    my %cookie = (
        name   => $name,
        value  => $id,
        domain => setting('session_domain'),
        secure => setting('session_secure'),
        http_only => defined(setting("session_is_http_only")) ?
                     setting("session_is_http_only") : 1,
        same_site => defined(setting("session_same_site")) ?
                    setting("session_same_site") : 'None',
    );
    if (my $expires = setting('session_expires')) {
        # It's # of seconds from the current time
        # Otherwise just feed it through.
        $expires = Dancer::Cookie::_epoch_to_gmtstring(time + $expires) if $expires =~ /^\d+$/;
        $cookie{expires} = $expires;
    }

    my $c = Dancer::Cookie->new(%cookie);
    Dancer::Cookies->set_cookie_object($name => $c);
}

1;
__END__

=pod

=head1 SPEC

=over 4

=item B<role>

A Dancer::Session object represents a session engine and should provide anything
needed to manipulate a session, whatever its storing engine is.

=item B<id>

The session id will be written to a cookie, by default named C<dancer.session>,
it is assumed that a client must accept cookies to be able to use a
session-aware Dancer webapp. (The cookie name can be change using the
C<session_name> config setting.)

=item B<storage engine>

When the session engine is enabled, a I<before> filter takes care to initialize
the appropriate session engine (according to the setting C<session>).

Then, the filter looks for a cookie named C<dancer.session> (or whatever you've
set the C<session_name> setting to, if you've used it) in order to
I<retrieve> the current session object. If not found, a new session object is
I<created> and its id written to the cookie.

Whenever a session call is made within a route handler, the singleton
representing the current session object is modified.

A I<flush> is made to the session object after every modification unless
the session engine overrides the C<is_lazy> method to return true.

=back

=head1 DESCRIPTION

This virtual class describes how to build a session engine for Dancer. This is
done in order to allow multiple session storage backends with a common interface.

Any session engine must inherit from Dancer::Session::Abstract and implement
the following abstract methods.

=head2 Configuration

These settings control how a session acts.

=head3 session_name

The default session name is "dancer_session". This can be set in your config file:

    setting session_name: "mydancer_session"

=head3 session_domain

Allows you to set the domain property on the cookie, which will
override the default.  This is useful for setting the session cookie's
domain to something like C<.domain.com> so that the same cookie will
be applicable and usable across subdomains of a base domain.

=head3 session_secure

The user's session id is stored in a cookie.  If true, this cookie
will be made "secure" meaning it will only be served over https.

=head3 session_expires

When the session should expire.  The format is either the number of
seconds in the future, or the human readable offset from
L<Dancer::Cookie/expires>.

By default, there is no expiration.

=head3 session_is_http_only

This setting defaults to 1 and instructs the session cookie to be
created with the C<HttpOnly> option active, meaning that JavaScript
will not be able to access to its value.

=head2 Abstract Methods

=over 4

=item B<retrieve($id)>

Look for a session with the given id, return the session object if found, undef
if not.

=item B<create()>

Create a new session, return the session object.

=item B<flush()>

Write the session object to the storage engine.

=item B<destroy()>

Remove the current session object from the storage engine.

=item B<session_name> (optional)

Returns a string with the name of cookie used for storing the session ID.

You should probably not override this; the user can control the cookie name
using the C<session_name> setting.

=item B<get_value($key)>

Retrieves the value associated with the key.

=item B<set_value($key, $value)>

Stores the value associated with the key.


=back

=head2 Inherited Methods

The following methods are not supposed to be overloaded, they are generic and
should be OK for each session engine.

=over 4

=item B<build_id>

Build a new uniq id.

By default, it is a 32-character, URL-safe, Base64 encoded combination of a
32-bit timestamp and 160 bits of random data generated by the operating
system's cryptographic random number generator via L<Crypt::URandom>.  The
timestamp ensures that session IDs are generally monotonic.

The generated ID is accepted by the default C<validate_session_id>, so no
further configuration is required.

=item B<validate_session_id>

Returns true if a session id is of the correct format, or false otherwise.

By default, this ensures that the session ID is a string of characters
from the Base64 schema for "URL Applications" plus the C<~> character,
and no longer than 4096 characters.  The length limit corresponds to the
maximum size of an HTTP cookie, so it accommodates cookie-based session
engines while rejecting oversized values that would otherwise be handed
to the backend unchanged.

=item B<read_session_id>

Reads the session ID from the cookie, ensuring it's syntactically valid.

=item B<write_session_id>

Write the current session id to the C<dancer.session> cookie.

=item B<is_lazy>

Default is false.  If true, session data will not be flushed after every
modification and the session engine (or application) will need to ensure
that a flush is called before the end of the request.

=back

=cut
