package Dancer::Serializer;

# Factory for logger engines

use strict;
use warnings;
use Dancer::ModuleLoader;
use Dancer::Engine;

my $engine;
sub engine {$engine}

sub init {
    my ($class, $name, $config) = @_;
    $engine = Dancer::Engine->build('Serializer' => 'Base', {});
}

1;

__END__
