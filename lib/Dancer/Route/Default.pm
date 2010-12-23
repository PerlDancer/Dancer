package Dancer::Route::Default;
use base 'Dancer::Route';

# Default route always matches!
sub match { return 1 }

1;
