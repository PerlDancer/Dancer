package Dancer::Template;

use strict;
use warnings;

# supported template engines
use Dancer::Template::Simple;
use Dancer::Template::TemplateToolkit;

# singleton for the current template engine
my $engine;
sub engine { $engine }

# init the engine according to the settings
sub init {
    my ($self, $setting) = @_;
    if ((not defined $setting) or ($setting eq 'simple')) {
        return $engine = Dancer::Template::Simple->new;
    }
    elsif ($setting eq 'template_toolkit') {
        return $engine = Dancer::Template::TemplateToolkit->new;
    }
    else {
        die "unknown template engine '$setting'";
    }
}

1;

