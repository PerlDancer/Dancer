package Dancer::Engine;

use strict;
use warnings;
use base 'Dancer::Object';

# constructor arguments:
#      name     => $name_of_the_engine
#      settings => $hash_of_engine_settings
Dancer::Engine->attributes(qw(name settings));

1;
__END__
