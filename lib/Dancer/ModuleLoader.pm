package Dancer::ModuleLoader;
# Abstraction layer for dynamic module loading

use strict;
use warnings;

sub load {
    my ($self, $module) = @_;
    local $@;
    eval "use $module";
    return $@ ? 0 : 1;
}

1;
