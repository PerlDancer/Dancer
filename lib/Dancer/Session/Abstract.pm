package Dancer::Session::Abstract;
use strict;
use warnings;

use Dancer::Cookies;
use File::Spec;

sub new {
    my ($class) = @_;
    my $self = {
        id => build_id(),
    };
    bless $self, $class;
    return $self;
}

# it's a constant, maybe a setting in the future
my $SESSION_NAME = 'dancer.session';

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
    Dancer::Cookies->cookies->{$SESSION_NAME};
}

sub write_session_id {
    my ($class, $id) = @_;
    Dancer::Cookies->cookies->{$SESSION_NAME} = $id;
}

sub retreive {
    die "retreive not implemented"
}

sub create {
    die "create not implemented"
}

sub flush {
    die "flush not implemented"
}

sub destroy {
    die "destroy not implemented"
}

1;
__END__
=pod

=head1 NAME

Dancer::Session::Abstract - Abstract class for session engine

=head1 SPEC

=over 4

=item B<role>

A Dancer::Session object represents a session engine and should provide anything
needed to manipulate a session, whatever its storing engine is.

=item B<id>

The session id will be written to a cookie, named C<dancer.session>, it is
assumed that a client must accept cookies to be able to use a session-aware 
Dancer webapp.

=item B<stroage engine>

When the session engine is enabled, a I<before> filter takes care to initialize
the good Dancer::Session::Engine (according to the setting C<session_engine>).

Then, the filter looks for a cookie named C<dancer.session> in order to
I<retreive> the current session object. If not found, a new session object is
I<created> and its id written to the cookie.

Whenever a session call is made within a route handler, the singleton
representing the current session object is modified.

After terminating the request, a I<flush> is made to the session object.

=back

=head1 SESSION ENGINES

The following engines are supported

=over 4

=item L<Dancer::Session::YAML> (C<session_engine: yaml>)

This engine stores sessions in YAML files located in the directory pointed by
the setting C<session_dir>, which default value is C<appdir/sessions>. 

This engine is not supposed to be used in production
environment but is very convinient for development purposes. As a matter of
fact, it's pretty handy for exploring a session to be able to just cat a file.

=item L<Dancer::Session::Binary> (C<session_engine: binary>)

This engine stores sessions in binary files located in the directory pointed by
the setting C<session_dir>, which default value is C<appdir/sessions>. 

Files are written with the Storable module. It's efficient and less 
space-consuming then the YAML engine.

=item L<Dancer::Session::Memcache> (C<session_engine: memcache>)

This engines stores session in memecache, it needs more settings to be work
correctly:

    session: 1
    session_engine: memcache
    session_engine_memcache_server: X.X.X.X
    session_engine_memcache_port: XXXX

=back

=item L<Dancer::Session::Mysql> (C<session_engine: mysql>)

This engine stores session in a MySQL database. The table for storing session
will be named C<dancer_sessions>.

    session: 1
    session_engine: mysql
    session_engine_mysql_server: 
    session_engine_mysql_port: 
    session_engine_mysql_username: 
    session_engine_mysql_password: 

=head1 DESCRIPTION

This virtual class describes how to build a session engine for Dancer. This is
done in order to allow multiple session storage with a common interface.

=head2 Abstract Methods 

The following methods must be implemented by any Dancer::Session class.

=over 4 

=item B<retreive($id)>

Look for a session with the given id, return the session object if found, undef
if not.

=item B<create()>

Create a new session, return the session object.

=item B<flush()>

Write the session object to the storage engine.

=item B<destroy()>

Remove the current session object from the storage engine.

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
