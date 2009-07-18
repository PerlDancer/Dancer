package Dancer::Config;

use strict;
use warnings;

# singleton for storing settings
my $SETTINGS = {};
sub settings { $SETTINGS };

# public accessor for adding/updating settings
sub update_setting {
    my ($class, $setting, $value) = @_;
    $SETTINGS->{$setting} = $value;
}

sub get_setting { settings()->{$_[1]} }

# load default settings

Dancer::Config->update_setting( server       => '127.0.0.1');
Dancer::Config->update_setting( port         => '1915'); # sinatra's birth year ;)
Dancer::Config->update_setting( content_type => 'text/html');
Dancer::Config->update_setting( charset      => 'UTF-8');

'Dancer::Config';
