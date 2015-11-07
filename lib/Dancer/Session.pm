package Dancer::Session;
our $AUTHORITY = 'cpan:SUKRIA';
#ABSTRACT: session engine for the Dancer framework
$Dancer::Session::VERSION = '1.3202';
use strict;
use warnings;

use Carp;
use Dancer::Cookies;
use Dancer::Engine;

# Singleton representing the session engine class to use
my $ENGINE = undef;
sub engine {$ENGINE}

# This wrapper look for the session engine and try to load it.
sub init {
    my ($class, $name, $config) = @_;
    $ENGINE = Dancer::Engine->build(session => $name, $config);

    #$ENGINE->init(); already done
}

# retrieve or create a session for the client
sub get_current_session {
    shift;
    my %p       = @_;
    my $sid     = engine->read_session_id;
    my $session = undef;
    my $class   = ref(engine);

    $session = $class->retrieve($sid) if $sid;

    if (not defined $session) {
        $session = $class->create();
    }

    # Generate a session cookie; we want to do this regardless of whether the
    # session is new or existing, so that the cookie expiry is updated.
    engine->write_session_id($session->id)
        unless $p{no_update};

    return $session;
}

sub get { get_current_session(@_) }

sub read {
    my ($class, $key) = @_;
    return unless $key;
    my $session = get_current_session();
    return $session->get_value($key);
}

sub write {
    my ($class, $key, $value) = @_;

    return unless $key;
    $key eq 'id' and croak 'Can\'t store to session key with name "id"';

    my $session = get_current_session();
    $session->set_value($key, $value);

    # TODO : should be moved as an "after" filter
    $session->flush unless $session->is_lazy;
    return $value;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dancer::Session - session engine for the Dancer framework

=head1 VERSION

version 1.3202

=head1 DESCRIPTION

This module provides support for server-side sessions for the L<Dancer> web
framework. The session is accessible to the user via an abstraction layer
implemented by the L<Dancer::Session> class.

=head1 USAGE

=head2 Configuration

The session engine must be first enabled in the environment settings, this can
be done like the following:

In the application code:

    # enabling the YAML-file-based session engine
    set session => 'YAML';

Or in config.yml or environments/$env.yml

    session: "YAML"

By default sessions are disabled, you must enable them before using it. If the
session engine is disabled, any Dancer::Session call will throw an exception.

See L<Dancer::Session::Abstract/Configuration> for more configuration options.

=head2 Route Handlers

When enabled, the session engine can be used in a route handler with the keyword
B<session>. This keyword allows you to store/retrieve values from the session by
name.

Storing a value into the session:

    session foo => 'bar';

Retrieving that value later:

    my $foo = session 'foo';

You can either look for an existing item in the session storage or modify one.
Here is a simple example of two route handlers that implement basic C</login>
and C</home> actions using the session engine.

    post '/login' => sub {
        # look for params and authenticate the user
        # ...
        if ($user) {
            session user_id => $user->id;
        }
    };

    get '/home' => sub {
        # if a user is present in the session, let him go, otherwise redirect to
        # /login
        if (not session('user_id')) {
            redirect '/login';
        }
    };

Of course, you probably don't want to have to duplicate the code to check
whether the user is logged in for each route handler; there's an example in the
L<Dancer::Cookbook> showing how to use a before filter to check whether the user
is logged in before all requests, and redirect to a login page if not.

=head1 SUPPORTED ENGINES

Dancer has a modular session engine that makes implementing new session backends
pretty easy. If you'd like to write your own, feel free to take a
look at L<Dancer::Session::Abstract>.

The following engines are supported out-of-the-box (shipped with the core Dancer
distribution):

=over 4

=item L<Dancer::Session::YAML>

A YAML file-based session backend, pretty convenient for development purposes,
but maybe not the best for production needs.

=item L<Dancer::Session::Simple>

A very simple session backend, holding all session data in memory.  This means
that sessions are volatile, and no longer exist when the process exits.  This
module is likely to be most useful for testing purposes, and of little use for
production.

=back

Additionally, many more session engines are available from CPAN, including:

=over 4

=item L<Dancer::Session::Memcached>

Session are stored in Memcached servers. This is good for production matters
and is a good way to use a fast, distributed session storage.  If you may be
scaling up to add additional servers later, this will be a good choice.

=item L<Dancer::Session::Cookie>

This module implements a session engine for sessions stored entirely
inside encrypted cookies (this engine doesn't use a server-side storage).

=item L<Dancer::Session::Storable>

This backend stores sessions on disc using Storable, which offers solid
performance and reliable serialization of various data structures.

=item L<Dancer::Session::MongoDB>

A backend to store sessions using L<MongoDB>

=item L<Dancer::Session::KiokuDB>

A backend to store sessions using L<KiokuDB>

=item L<Dancer::Session::PSGI>

Let Plack::Middleware::Session handle sessions; may be useful to share sessions
between a Dancer app and other Plack-based apps.

=back

=head1 DEPENDENCY

Dancer::Session may depend on third-party modules, depending on the session
engine used. See the session engine module for details.

=head1 AUTHORS

This module has been written by Alexis Sukrieh. See the AUTHORS file that comes
with this distribution for details.

=head1 LICENSE

This module is free software and is released under the same terms as Perl
itself.

=head1 SEE ALSO

See L<Dancer> for details about the complete framework.

=head1 AUTHOR

Dancer Core Developers

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Alexis Sukrieh.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
