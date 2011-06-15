package Dancer::Session::YAML;
# ABSTRACT: YAML-file-based session backend for Dancer

=head1 DESCRIPTION

This module implements a session engine based on YAML files. Session
are stored in a I<session_dir> as YAML files. The idea behind this
module was to provide a transparent session storage for the developer.

This backend is intended to be used in development environments, when
looking inside a session can be useful.

It's not recommended to use this session engine in production
environments.

=cut

use strict;
use warnings;
use Carp;
use base 'Dancer::Session::Abstract';

use Dancer::Logger;
use Dancer::ModuleLoader;
use Dancer::Config 'setting';
use Dancer::FileUtils qw(path set_file_mode);
use File::Copy;
use File::Temp qw(tempfile);

my %session_dir_initialized;


=method init

Check C<init> documentation on L<Dancer::Session>.

=cut
sub init {
    my $self = shift;
    $self->SUPER::init(@_);

    if (!keys %session_dir_initialized) {
        croak "YAML is needed and is not installed"
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
              or croak "session_dir $session_dir cannot be created";
        }
        Dancer::Logger::core("session_dir : $session_dir");
    }
}

=method create

Check C<create> documentation on L<Dancer::Session>.

=cut
sub create {
    my ($class) = @_;

    my $self = Dancer::Session::YAML->new;
    $self->flush;
    return $self;
}


=method reset

to avoid checking if the sessions directory exists everytime a new
session is created, this module maintains a cache of session
directories it has already created. C<reset> wipes this cache out,
forcing a test for existence of the sessions directory next time a
session is created. It takes no argument.

This is particulary useful if you want to remove the sessions
directory on the system where your app is running, but you want this
session engine to continue to work without having to restart your
application.

=cut
sub reset {
    my ($class) = @_;
    %session_dir_initialized = ();
}

=method retrieve

Check C<retrieve> documentation on L<Dancer::Session>.

=cut
sub retrieve {
    my ($class, $id) = @_;

    my $file = _yaml_file($id);
    return unless -f $file;
    return YAML::LoadFile($file);
}

=method destroy

Check C<destroy> documentation on L<Dancer::Session>.

=cut
sub destroy {
    my ($self) = @_;
    my $file = _yaml_file($self->id);

    use Dancer::Logger;
    Dancer::Logger::core("trying to remove session file: $file");
    unlink $file if -f $file;
}

=method flush

Check C<flush> documentation on L<Dancer::Session>.

=cut
sub flush {
    my $self = shift;
    my ( $fh, $tmpname ) =
      tempfile( $self->id . '.XXXXXXXX', DIR => setting('session_dir') );
    set_file_mode($fh);
    print {$fh} YAML::Dump($self);
    close $fh;
    move($tmpname, _yaml_file($self->id));
    return $self;
}

# private
sub _yaml_file {
    my ($id) = @_;
    return path(setting('session_dir'), "$id.yml");
}

1;
__END__

=head1 CONFIGURATION

The setting B<session> should be set to C<YAML> in order to use this
session engine in a Dancer application.

Files will be stored to the value of the setting C<session_dir>, whose
default value is C<appdir/sessions>.

Here is an example configuration that use this session engine and
stores session files in /tmp/dancer-sessions

    session: "YAML"
    session_dir: "/tmp/dancer-sessions"

=head1 DEPENDENCY

This module depends on L<YAML>.

=cut
