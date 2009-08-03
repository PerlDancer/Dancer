package Dancer::Environment;

use strict;
use warnings;
use Carp 'confess';
use Dancer::FileUtils 'path';
use Dancer::Config 'setting';

sub load {
    my ($class, $env) = @_;
    return 1 if not defined $env;

    my $path = $class->environment_file($env);

    confess "Environment `$env' not found"
        unless defined $path;

    do $path or confess "Unable to load environment file `$path': $@";
}

sub environment_file {
    my ($class, $env) = @_;
    my $path = path(setting('appdir'), 'environments', "$env.pl");
    return (-e $path && -r $path) ? $path : undef;
}

'Dancer::Environment';
__END__
