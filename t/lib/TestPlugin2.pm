package TestPlugin2;

use strict;
use warnings;

use Dancer ':syntax';
use Dancer::Plugin;

use base qw(Data::Dumper);

register some_other_plugin_keyword => sub {
    42;
};

register_plugin;
1;
