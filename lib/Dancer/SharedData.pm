package Dancer::SharedData;

use strict;
use warnings;
use Dancer::Timer;
use Dancer::Response;

# shared variables
my $vars = {};
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

# current response
my $_response;
sub response {
    if (@_ == 2) {
        $_response = $_[1];
    }else{
        $_response = Dancer::Response->new() if !defined $_response;
        return $_response;
    }
}
sub reset_response { $_response = undef }

# request timer
my $_timer;
sub timer { $_timer ||= Dancer::Timer->new }
sub reset_timer { $_timer = Dancer::Timer->new }

# purging accessor
sub reset_all {
    my ($self, %options) = @_;

    if (!exists($options{reset_vars}) || $options{reset_vars}) {
        $vars = {};
    }
    undef $_request;
    undef $_headers;
    reset_timer();
    reset_response();
}

'Dancer::SharedData';
