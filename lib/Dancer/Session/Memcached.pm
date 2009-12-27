package Dancer::Session::Memcached;

use strict;
use warnings;
use base 'Dancer::Session::Abstract';

use Dancer::Config 'setting';
use Dancer::ModuleLoader;

# static

# singleton for the Memcached hanlde
my $MEMCACHED = undef;

sub init {
    my ($class) = @_;
    
    die "Cache::Memcached is needed and is not installed"
        unless Dancer::ModuleLoader->load('Cache::Memcached');

    my $servers = setting("memcached_servers");
    die "The setting memcached_servers must be defined"
      unless defined $servers;
    $servers = [split /,/, $servers];

    # make sure the servers look good
    foreach my $s (@$servers) {
        if ($s =~ /^\d+\.\d+\.\d+\.\d+$/) {
            die "server `$s' is invalid; port is missing, use `server:port'";
        }
    }
    
    Dancer::Logger->debug("memcached servers set to ".join(", ", @$servers));
    $MEMCACHED = Cache::Memcached->new(servers => $servers);
}

# create a new session and return the newborn object
# representing that session
sub create {
    my ($class) = @_;
    my $self = $class->new;
    $MEMCACHED->set($self->id => $self);
    return $self;
}

# Return the session object corresponding to the given id
sub retrieve($$) {
    my ($class, $id) = @_;
    return $MEMCACHED->get($id);
}

# instance 

sub destroy {
    my ($self) = @_;
    $MEMCACHED->delete($self->id);
}

sub flush {
    my $self = shift;
    $MEMCACHED->set($self->id => $self);
    return $self;
}

1;
__END__
=pod

=head1 NAME

Dancer::Session::Memcache - Memcache-based session backend for Dancer

=head1 DESCRIPTION

This module implements a session engine based on the Memcache API. Session are stored
as memcache objects via a list of Memcached servers.

=head1 CONFIGURATION

The setting B<session> should be set to C<memcached> in order to use this session
engine in a Dancer application.

A mandatory setting is needed as well: C<memcached_servers>, which should
contain a comma-separated list of reachable memecached servers (can be either 
address:port or sockets).

Here is an example configuration that uses this session engine

    session: "memcached"
    memcached_servers: "10.0.1.31:11211,10.0.1.32:11211,10.0.1.33:11211,/var/sock/memcached"

=head1 DEPENDENCY

This module depends on L<Cache::Memcached>.

=head1 AUTHOR

This module has been written by Alexis Sukrieh, see the AUTHORS file for
details.

=head1 SEE ALSO

See L<Dancer::Session> for details about session usage in route handlers.

=head1 COPYRIGHT

This module is copyright (c) 2009 Alexis Sukrieh <sukria@sukria.net>

=head1 LICENSE

This module is free software and is released under the same terms as Perl
itself.

=cut
1;
