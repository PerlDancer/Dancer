use strict;
use warnings;

use Test::More tests => 3;

use Dancer ':tests';

prefix '/foo';

get '0' => sub { '0' };

# useful when we have prefixes and want to 
# use the prefix url too. E.g., here /foo
get ''  => sub { '' };

get ' ' => sub { ' ' };

use Dancer::Test;

response_content_is "/foo$_" => $_ for '', 0, ' ';



