package Dancer::Error;

use strict;
use warnings;
use Data::Dumper;

use Dancer::Response;
use Dancer::Renderer;
use Dancer::Config 'setting';

sub new {
    my ($class, %params) = @_;
    my $self = \%params;
    bless $self, $class;

    $self->{title}   ||= "Error ".$self->code;
    $self->{message} ||= "<h2>Unknown Error</h2>";
    $self->{message} .= $self->environment;

    return $self;
}

sub code    { $_[0]->{code}    }
sub title   { $_[0]->{title}   }
sub message { $_[0]->{message} }

sub render {
    my $self = shift;
    return Dancer::Response->new(
        status  => $self->code,
        headers => {'Content-Type' => 'text/html'},
        content => Dancer::Renderer->html_page($self->title, $self->message))
        if setting('show_errors');
    
    return Dancer::Renderer->render_error($self->code);
}

sub environment {
    my ($self) = @_;

    my $env = "<h3>Environment</h3><pre>".Dumper(\%ENV)."</pre>";
    my $settings = "<h3>Settings</h3><pre>".Dumper(Dancer::Config->settings)."</pre>";
    my $source = "<h3>Stack</h3><pre>".$self->get_caller."</pre>";
    return "$source $env $settings";
}

sub get_caller {
    my ($self) = @_;
    my @stack;

    my $deepness = 0;
    while (my ($package, $file, $line) = caller($deepness++)) {
        push @stack, "$package in $file l. $line";
    }

    return join("\n", reverse(@stack));
}

1;
