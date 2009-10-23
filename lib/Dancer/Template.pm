package Dancer::Template;

use strict;
use warnings;
use Dancer::Config 'setting';

# supported template engines
use Dancer::Template::Simple;
use Dancer::Template::TemplateToolkit;

# singleton for the current template engine
my $engine;
sub engine { $engine }

# init the engine according to the settings
sub init {
    my $t = setting('template');
    if ((not defined $t) or ($t eq 'simple')) {
        return $engine = Dancer::Template::Simple->new;
    }
    elsif ($t eq 'template_toolkit') {
        return $engine = Dancer::Template::TemplateToolkit->new;
    }
    else {
        die "unknown template engine '$t'";
    }
}

1;

