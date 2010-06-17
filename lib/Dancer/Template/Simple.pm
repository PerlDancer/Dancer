package Dancer::Template::Simple;
use strict;
use warnings;

use base 'Dancer::Template::TemplateToolkit';

sub init {
    my $self = shift;
    warn "Dancer::Template::Simple is deprecated, use another engine";
    $self->SUPER::init(@_);
}

1;
