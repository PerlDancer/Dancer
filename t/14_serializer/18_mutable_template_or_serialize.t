use strict;
use warnings;

use Test::More;

plan skip_all => "need JSON"
    unless Dancer::ModuleLoader->load('JSON');

plan tests => 2;

use Dancer ':tests';
use Dancer::Test;

use Dancer::Serializer::Mutable qw/ template_or_serialize /;

set serializer => 'Mutable';

no warnings 'redefine';
sub Dancer::template {
    return $_[0];
}

get '/' => sub {
    template_or_serialize 'index', { a => 1 };    
};

my $resp = dancer_response GET => '/';

like $resp->content => qr/"a"\s*:\s*1/, "serialized to JSON";

$resp = dancer_response GET => '/', { params => {  
    content_type => 'text/html'
} };

is $resp->content => 'index', 'use the template';

