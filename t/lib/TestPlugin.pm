package TestPlugin;

use strict;
use warnings;

use Dancer ':syntax';
use Dancer::Plugin;

register some_plugin_keyword => sub {
    42;
};

register_plugin;
1;
