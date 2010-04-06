use Test::More import => ['!pass'];

use strict;
use warnings;

use Dancer ':syntax';
use Dancer::Plugin::FromTo;

plan tests => 9;

my $struct = { eris => 23 };

ok my $test         = to_json($struct), 'to json';
ok my $final_struct = from_json($test), 'from json';
is_deeply $final_struct, $struct, 'from => to works';

ok $test         = to_yaml($struct), 'to yaml';
ok $final_struct = from_yaml($test), 'from yaml';
is_deeply $final_struct, $struct, 'from => to works';

ok $test         = to_xml($struct), 'to xml';
ok $final_struct = from_xml($test), 'from xml';
is_deeply $final_struct->{data}, $struct, 'from => to works';
