package TestPlugin;

use strict;
use warnings;
use Dancer::Plugin;

register 'test_plugin_symbol' => sub {
    "test_plugin_symbol";
};

register_plugin;
1;
