use strict;
use warnings;

use Dancer;

set engines => {
    template_toolkit => {
        embedded_templates => 1,
    },
};

set template => 'template_toolkit';

get '/' => sub { template 'hello' };

1;

__DATA__

__hello__
Hello embedded world!
