package Dancer::Request;
# webservers handling is a hell
# this class is the common gateway interface
# for getting infoirmation about the current
# request, whatever the underlying webserver.

use strict;
use warnings;
use Dancer::SharedData;

sub new {
    my ($class, $cgi) = @_;
    my $self = {
        path => undef,
        method => undef,
        _cgi => $cgi || Dancer::SharedData->cgi,
    };
    bless $self, $class;
    $self->init();
    return $self;
}

# public interface (read-only)
sub path   { $_[0]->{path}   }
sub method { $_[0]->{method} }

# private
sub init {
    my ($self) = @_;
    $self->build_path();
    $self->build_method();
}

sub build_path {
    my ($self) = @_;

    my $path = "";
    my $req = $self->{_cgi};
    if (defined $ENV{'SCRIPT_NAME'}) {
        $path = $ENV{'SCRIPT_NAME'};
        $path .= $ENV{'PATH_INFO'} if $ENV{'PATH_INFO'};
    }
    else {
        # look for script name
        my $script_name = "";
        eval { $script_name = $req->script_name }; 
        $path .= $script_name if defined $script_name;
        $path .= $req->path_info if defined $req->path_info;
    }

    die "Cannot resolve path" if not $path;
    $self->{path} = $path;
}

sub build_method {
    my ($self) = @_;
    $self->{method} = $ENV{REQUEST_METHOD} || $self->{_cgi}->request_method();
}

1;
