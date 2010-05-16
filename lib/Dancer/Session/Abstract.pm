package Dancer::Session::Abstract;
use strict;
use warnings;

use base 'Dancer::Engine';

use Dancer::Config 'setting';
use Dancer::Cookies;
use File::Spec;

__PACKAGE__->attributes('id');

# args: ($class)
# Overload this method in your session engine if you have some init stuff to do,
# such as a database connection or making sure a directory exists...
# It will be called once the session engine is loaded.
# sub init { return 1; }

# args: ($class, $id)
# receives a session id and should return a session object if found, or undef
# otherwise.
sub retrieve {
    die "retrieve not implemented";
}

# args: ($class)
# create a new empty session, flush it and return it.
sub create {
    die "create not implemented";
}

# args: ($self)
# write the (serialized) current session to the session storage
sub flush {
    die "flush not implemented";
}

# args: ($self)
# remove the session from the session storage
sub destroy {
    die "destroy not implemented";
}


# Methods below this this line should not be overloaded.

# This is the default constructor for the session object, the only mandatory
# attribute is 'id'. The whole object should be serialized by the session
# engine.
sub new {
    my $self = Dancer::Object::new(@_);
    $self->id(build_id());
    return $self;
}

# session name can be set in configuration file:
# setting session_name => 'mydancer.session';
my $SESSION_NAME = session_name();

# this method can be overwrite in any Dancer::Session::* module
sub session_name {
    setting('session_name') || 'dancer.session';
}

# we try to make the best random number
# with native Perl 5 code.
# to rebuild a session id, an attacker should know:
# - the running PID of the server
# - the current timestamp of the time it was built
# - the path of the installation directory
# - guess the correct number between 0 and 1000000000
# - should be able to reproduce that 3 times
sub build_id {
    my $session_id = "";
    foreach my $seed (rand(1000), rand(1000), rand(1000)) {
        my $c = 0;
        $c += ord($_) for (split //, File::Spec->rel2abs(File::Spec->curdir));
        my $current = int($seed * 1000000000) + time + $$ + $c;
        $session_id .= $current;
    }
    return $session_id;
}

sub read_session_id {
    my $c = Dancer::Cookies->cookies->{$SESSION_NAME};
    return (defined $c) ? $c->value : undef;
}

sub write_session_id {
    my ($class, $id) = @_;
    Dancer::Cookies->cookies->{$SESSION_NAME} = Dancer::Cookie->new(
        name  => $SESSION_NAME,
        value => $id,

        # no expires: will expire when the browser is closed
    );
}

1;
__END__

=pod

=head1 NAME

Dancer::Session::Abstract - abstract class for session engine

=head1 SPEC

=over 4

=item B<role>

A Dancer::Session object represents a session engine and should provide anything
needed to manipulate a session, whatever its storing engine is.

=item B<id>

The session id will be written to a cookie, named C<dancer.session>, it is
assumed that a client must accept cookies to be able to use a session-aware
Dancer webapp.

=item B<storage engine>

When the session engine is enabled, a I<before> filter takes care to initialize
the good Dancer::Session::Engine (according to the setting C<session>).

Then, the filter looks for a cookie named C<dancer.session> in order to
I<retrieve> the current session object. If not found, a new session object is
I<created> and its id written to the cookie.

Whenever a session call is made within a route handler, the singleton
representing the current session object is modified.

After terminating the request, a I<flush> is made to the session object.

=back

=head1 DESCRIPTION

This virtual class describes how to build a session engine for Dancer. This is
done in order to allow multiple session storage with a common interface.

Any session engine must inherits from Dancer::Session::Abstract and implement
the following abstract methods.

The default session name is "dancer_session". This can be set in your config file:

    setting session_name: "mydancer_session"

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

=back

=head2 Inherited Methods

The following methods are not supposed to be overloaded, they are generic and
should be OK for each session engine.

=over 4

=item B<build_id>

Build a new uniq id.

=item B<read_session_id>

Reads the C<dancer.session> cookie.

=item B<write_session_id>

Write the current session id to the C<dancer.session> cookie.

=back

=cut
