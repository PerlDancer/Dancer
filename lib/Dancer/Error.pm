package Dancer::Error;

use strict;
use warnings;

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

sub dumper {
    my $obj = shift;

    my $content = "";
    while (my ($k, $v) = each %$obj) {
        $content .= "<span class=\"key\">$k</span> : <span class=\"value\">$v</span>\n";
    }
    return $content;
}

sub render {
    my $self = shift;
    return Dancer::Response->new(
        status  => $self->code,
        headers => {'Content-Type' => 'text/html'},
        content => Dancer::Renderer->html_page(
                       $self->title, $self->message, 'error'))
        if setting('show_errors');
    
    return Dancer::Renderer->render_error($self->code);
}

sub environment {
    my ($self) = @_;

    my $env = "<h3>Environment</h3><pre>".dumper(\%ENV)."</pre>";
    my $settings = "<h3>Settings</h3><pre>".dumper(Dancer::Config->settings)."</pre>";
    my $source = "<h3>Stack</h3><pre>".$self->get_caller."</pre>";
    return "$source $settings $env";
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
