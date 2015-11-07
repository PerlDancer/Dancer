package Dancer::Session::YAML;
our $AUTHORITY = 'cpan:SUKRIA';
#ABSTRACT: YAML-file-based session backend for Dancer
$Dancer::Session::YAML::VERSION = '1.3202';
use strict;
use warnings;
use Carp;
use base 'Dancer::Session::Abstract';

use Dancer::Logger;
use Dancer::ModuleLoader;
use Dancer::Config 'setting';
use Dancer::FileUtils qw(path atomic_write);
use Dancer::Exception qw(:all);

# static

my %session_dir_initialized;

sub init {
    my $self = shift;
    $self->SUPER::init(@_);

    if (!keys %session_dir_initialized) {
        raise core_session => "YAML is needed and is not installed"
          unless Dancer::ModuleLoader->load('YAML');
    }

    # default value for session_dir
    setting('session_dir' => path(setting('appdir'), 'sessions'))
      if not defined setting('session_dir');

    my $session_dir = setting('session_dir');
    if (! exists $session_dir_initialized{$session_dir}) {
        $session_dir_initialized{$session_dir} = 1;
        # make sure session_dir exists
        if (!-d $session_dir) {
            mkdir $session_dir
              or raise core_session => "session_dir $session_dir cannot be created";
        }
        Dancer::Logger::core("session_dir : $session_dir");
    }
}

# create a new session and return the newborn object
# representing that session
sub create {
    my ($class) = @_;

    my $self = Dancer::Session::YAML->new;
    $self->flush;
    return $self;
}

# deletes the dir cache
sub reset {
    my ($class) = @_;
    %session_dir_initialized = ();
}

# Return the session object corresponding to the given id
sub retrieve {
    my ($class, $id) = @_;

    unless( $id =~ /^[\da-z]+$/i ) {
        warn "session id '$id' contains illegal characters\n";
        return;
    }

    my $session_file = yaml_file($id);

    return unless -f $session_file;

    open my $fh, '+<', $session_file or die "Can't open '$session_file': $!\n";
    my $content = YAML::LoadFile($fh);
    close $fh or die "Can't close '$session_file': $!\n";

    return $content;
}

# instance

sub yaml_file {
    my $id = shift;

    return path(setting('session_dir'), "$id.yml");
}

sub destroy {
    my ($self) = @_;
    use Dancer::Logger;
    Dancer::Logger::core(
        "trying to remove session file: " . yaml_file($self->id));
    unlink yaml_file($self->id) if -f yaml_file($self->id);
}

sub flush {
    my $self         = shift;
    my $session_file = yaml_file( $self->id );

    atomic_write( setting('session_dir'), yaml_file($self->id), YAML::Dump($self) );

    return $self;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dancer::Session::YAML - YAML-file-based session backend for Dancer

=head1 VERSION

version 1.3202

=head1 DESCRIPTION

This module implements a session engine based on YAML files. Session are stored
in a I<session_dir> as YAML files. The idea behind this module was to provide a
transparent session storage for the developer. 

This backend is intended to be used in development environments, when looking
inside a session can be useful.

It's not recommended to use this session engine in production environments.

=head1 CONFIGURATION

The setting B<session> should be set to C<YAML> in order to use this session
engine in a Dancer application.

Files will be stored to the value of the setting C<session_dir>, whose default 
value is C<appdir/sessions>.

Here is an example configuration that use this session engine and stores session
files in /tmp/dancer-sessions

    session: "YAML"
    session_dir: "/tmp/dancer-sessions"

=head1 METHODS

=head2 reset

To avoid checking if the sessions directory exists every time a new session is
created, this module maintains a cache of session directories it has already
created. C<reset> wipes this cache out, forcing a test for existence
of the sessions directory next time a session is created. It takes no argument.

This is particularly useful if you want to remove the sessions directory on the
system where your app is running, but you want this session engine to continue
to work without having to restart your application.

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

=head1 AUTHOR

Dancer Core Developers

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Alexis Sukrieh.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
