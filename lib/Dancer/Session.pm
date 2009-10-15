package Dancer::Session;

use strict;
use warnings;

use Dancer::Cookies;
use Dancer::Config 'setting';
use Dancer::ModuleLoader;

my $ENGINE = undef;

sub init {
    my ($class, $setting) = @_;
    if ($setting eq 'yaml') {
        die "YAML is needed for the YAML session engine" 
            unless Dancer::ModuleLoader->load('YAML');
        eval "use Dancer::Session::YAML";
        $ENGINE = 'Dancer::Session::YAML';
    }
    else {
        die "unsupported session engine: `$setting'";
    }
}

# retreive or create a session for the client
sub get_current_session {
    my $sid = $ENGINE->read_session_id;
    my $session;

    if ($sid) {
        Dancer::Logger->debug("sid found: '$sid'");
        $session = $ENGINE->retreive($sid);
    }
    else {
        $session = $ENGINE->create();
        Dancer::Logger->debug("new session created => ".$session->{id});
        $ENGINE->write_session_id($session->{id});
    }
    return $session;
}

sub read {
    my ($class, $key) = @_;
    my $session = get_current_session();
    return $session->{$key};
}

sub write {
    my ($class, $key, $value) = @_;
    my $session = get_current_session();
    $session->{$key} = $value;
    
    # TODO : should be moved as an "after" filter
    $session->flush;
    return $value;
}

1;
__END__
=pod

=head1 NAME

Dancer::Session - session engine for the Dancer framework

=head1 DESCRIPTION

This module provides support for server-side session for the Dancer micro
framework. The session is accessible to the user via an abstraction layer
implemented by the Dancer::Session class.

=head1 USAGE

=head2 Configuration

The session engine must be first enabled in the environment settings, this can
be done like the following:

In the application code:

    # myapp.pm
    set session => true;

Or in config.yml or environments/$env.yml

    session: 1

By default session are disabled, you must enable them before using it. If the
session engine is disabled, any Dancer::Session call will throw an exception.

=head2 Route Handlers

When enabled, the session engine can be used in a route handler with the keyword
B<session>. This keyword represents a key-value pairs ensemble that is actually
stored to the session.

You can either look for an existing item in the session storage or modify one.
Here is a simple example of two route handlers that implement a basic C</login> and
C</home> actions using the session engine. 

    post '/login' => {
        # look for params and authenticate the user
        # ...
        if ($user) {
            session user_id => $user->id;
        }
    };

    get '/home' => {
        # if a user is present in the session, let him go, otherwise redirect to
        # /login
        if (not session->{user_id}) {
            redirect '/login';
        }
    };

=head1 DEPENDENCY

Dancer::Session may depends on third-party modules, depending on the session
engine used. See the session engine module for details.

=head1 AUTHORS

This module has been written by Alexis Sukrieh. See the AUTHORS file that comes
with this distribution for details.

=head1 LICENSE

This module is free software and is released under the same terms as Perl
itself.

=head1 SEE ALSO

See L<Dancer> for details about the complete framework.

=cut
