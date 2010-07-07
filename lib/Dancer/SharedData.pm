package Dancer::SharedData;

use strict;
use warnings;
use Dancer::Timer;

# shared variables
my $vars   = {};
sub vars {$vars}
sub var {
    my ($class, $key, $value) = @_;
    $vars->{$key} = $value if (@_ == 3);
    return $vars->{$key};
}

# request headers
my $_headers;
sub headers { (@_ == 2) ? $_headers = $_[1] : $_headers }

# request singleton
my $_request;
sub request { (@_ == 2) ? $_request = $_[1] : $_request }

# request timer
my $_timer;
sub timer { $_timer ||= Dancer::Timer->new };
sub reset_timer { $_timer = Dancer::Timer->new };

# purging accessor
sub reset_all {
    $vars   = {};
    undef $_request;
    undef $_timer;
    undef $_headers;
}


'Dancer::SharedData';
