package Dancer::Template;

use strict;
use warnings;

# singleton for the current template engine
my $engine;
sub engine { $engine }

# init the engine according to the settings
sub init {
    my ($self, $setting, $config) = @_;
    if ((not defined $setting) or ($setting eq 'simple')) {
        require Dancer::Template::Simple;
        return $engine = Dancer::Template::Simple->new;
    }
    elsif ($setting eq 'template_toolkit') {
        require Dancer::Template::TemplateToolkit;
        return $engine = Dancer::Template::TemplateToolkit->new(settings => $config);
    }elsif($setting eq 'micro_template') {
        require Dancer::Template::MicroTemplate;
        return $engine = Dancer::Template::MicroTemplate->new(settings => $config);
    }else {
        die "unknown template engine '$setting'";
    }
}

1;

