package Dancer::Config;

use strict;
use warnings;
use base 'Exporter';
use vars '@EXPORT_OK';

@EXPORT_OK = qw(setting);

# singleton for storing settings
my $SETTINGS = {};

# public accessor for get/set
sub setting {
    my ($setting, $value) = @_;
    (@_ == 2) 
        ? $SETTINGS->{$setting} = $value
        : $SETTINGS->{$setting} ;
}

# load default settings

setting( server       => '127.0.0.1');
setting( port         => '1915'); # sinatra's birth year ;)
setting( content_type => 'text/html');
setting( charset      => 'UTF-8');
setting( access_log   => 1);

'Dancer::Config';
