package Dancer::Session::YAML;

use strict;
use warnings;
use base 'Dancer::Session::Abstract';

use Dancer::FileUtils 'path';

# TODO : should be a setting
my $SESSION_DIR = '/tmp/dancer.sessions';

# static

# create a new session and return the newborn object
# representing that session
sub create {
    my ($class) = @_;
    mkdir $SESSION_DIR unless -d $SESSION_DIR;

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
