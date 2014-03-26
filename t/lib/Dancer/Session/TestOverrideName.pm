package Dancer::Session::TestOverrideName;

#
# a simple test wrapper for session with name overridden
#

use strict;
use warnings;
our $VERSION = '0.01';

use base 'Dancer::Session::Abstract';

sub session_name {
    "dr_seuss";
}

1;
