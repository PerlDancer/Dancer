package Dancer::Serializer;

# Factory for logger engines

use strict;
use warnings;
use Dancer::ModuleLoader;
use Dancer::Engine;

my $_engine;
sub engine {$_engine}

# TODO : change the serializer according to $name
sub init {
    my ($class, $name) = @_;
    $_engine = Dancer::Engine->build('Serializer' => 'Base', {});
}

1;

__END__
