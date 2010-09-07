use strict;
use warnings;
use Test::More;

plan tests => 1;

use Dancer::FileUtils qw/read_file_content/;

my $content = read_file_content();
ok !$content;
