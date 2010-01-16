use Test::More 'no_plan';
use strict;
use warnings; 

use Dancer::Request;
use CGI;

$ENV{REQUEST_METHOD} = 'GET';
$ENV{PATH_INFO} = '/';
$ENV{QUERY_STRING} = 'key1=val1';

{
    my $q = CGI->new;
    my $r = Dancer::Request->new();
    Dancer::Request->normalize($q);
    my $p = $r->params;
    is($p->{'key1'},'val1', "basic test of normalize with CGI object and params"); 
}
{
    $ENV{QUERY_STRING} = 'key2=val1&key2=val2';
    my $q = CGI->new;
    my $r = Dancer::Request->new();
    Dancer::Request->normalize($q);
    my $p = $r->params;
    is_deeply($p->{'key2'}, ['val1','val2'], "normalize() and params(): multi-valued params are supported.");
}
