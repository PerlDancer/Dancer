use strict;
use warnings;

use Dancer::Serializer;
use Test::More import => ['!pass'];

plan skip_all => "JSON is needed to run this tests" unless Dancer::ModuleLoader->load('JSON');

ok my $s = Dancer::Serializer->init();

my $ct = $s->support_content_type();
ok !defined $ct;

$ct = $s->content_type();
is $ct, 'application/json';

done_testing;
