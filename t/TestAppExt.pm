package TestAppExt;

use strict;
use warnings;

use lib 't';
use Dancer ':syntax';
use TestPlugin;

sub test_app_func { test_plugin_symbol() }

1;
