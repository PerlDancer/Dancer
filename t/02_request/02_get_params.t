use Test::More tests => 5;

use strict;
use warnings FATAL => 'all';
use Dancer::Request;

$ENV{REQUEST_METHOD} = 'GET';
$ENV{PATH_INFO} = '/';
$ENV{QUERY_STRING} = 'name=Alexis%20Sukrieh&IRC%20Nickname=sukria&Project=Perl+Dancer&hash=2&hash=4';

my $expected_params = {
    'name' => 'Alexis Sukrieh',
    'IRC Nickname' => 'sukria',
    'Project' => 'Perl Dancer',
    'hash' => [2, 4],
};

my $req = Dancer::Request->new;
is $req->path, '/', 'path is set';
is $req->method, 'GET', 'method is set';

is_deeply scalar($req->params), $expected_params, 'params are OK';
is $req->params->{'name'}, 'Alexis Sukrieh', 'params accessor works';

my %params = $req->params;
is_deeply scalar($req->params), \%params, 'params wantarray works';

