package Dancer::Session::YAML;

use strict;
use warnings;
use base 'Dancer::Session::Abstract';

use Dancer::Config 'setting';
use Dancer::FileUtils 'path';

my $SESSION_DIR = undef;

# static

sub init {
    my ($class) = @_;
    setting('session_dir' => path(setting('appdir'), 'sessions'))
        if not defined setting('session_dir');
    $SESSION_DIR = setting('session_dir');
    if (! -d $SESSION_DIR) {
        mkdir $SESSION_DIR 
            or die "session_dir $SESSION_DIR cannot be created";
    }
    Dancer::Logger->debug("session_dir : $SESSION_DIR");
}

# create a new session and return the newborn object
# representing that session
sub create {
    my ($class) = @_;

    my $self = Dancer::Session::YAML->new;
    $self->flush;
    return $self;
}

# Return the session object corresponding to the given id
sub retreive($$) {
    my ($class, $id) = @_;

    my $session = path($SESSION_DIR, "$id.yml");
    return undef unless -f $session;
    return YAML::LoadFile($session);
}

# instance 
sub destroy {
    die 'TODO';
}

sub flush {
    my $self = shift;
    open SESSION, '>', path($SESSION_DIR, $self->{id}.".yml") or die $!;
    print SESSION YAML::Dump($self);
    close SESSION;
    return $self;
}

1;
__END__
=pod

=head1 NAME

Dancer::Session::YAML - YAML-file-based session backend for Dancer

=head1 DESCRIPTION

This module implements a session engine based on YAML files. Session are stored
in a I<session_dir> as YAML files. The idea behind this module was to provide a
transparent session storage for the developer. 

This backend is intended to be used in development environments, when looking
inside a session can be useful.

It's not recommended to use this session engine in production environements.

=head1 CONFIGURATION

The setting B<session> should be set to C<yaml> in order to use this session
engine in a Dancer application.

Files will be stored to the value of the setting C<session_dir>, which default value is
C<appdir/sessions>.

Here is an example configuration that use this session engine and stores session
files in /tmp/dancer-sessions

    session: "yaml"
    session_dir: "/tmp/dancer-sessions"

=head1 DEPENDENCY

This module depends on L<YAML>.

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
