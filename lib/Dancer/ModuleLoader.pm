package Dancer::ModuleLoader;

# Abstraction layer for dynamic module loading

use strict;
use warnings;

sub load {
    my ($class, $module) = @_;
    local $@;
    eval "use $module";
    return $@ ? 0 : 1;
}

sub require {
    my ($class, $module) = @_;
    local $@;
    eval "require $module";
    return $@ ? 0 : 1;
}

sub class_from_setting {
    my ($self, $namespace, $setting) = @_;

    my $class = "";
    for my $token (split /_/, $setting) {
        $class .= ucfirst($token);
    }
    return "${namespace}::${class}";
}

1;
