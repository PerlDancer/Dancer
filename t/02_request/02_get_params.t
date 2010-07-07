use Test::More tests => 10;

use strict;
use warnings FATAL => 'all';
use Dancer::Request;

$ENV{REQUEST_METHOD} = 'GET';
$ENV{PATH_INFO} = '/';

for my $separator ('&', ';') {
    $ENV{QUERY_STRING} = join($separator, 
        ('name=Alexis%20Sukrieh',
        'IRC%20Nickname=sukria',
        'Project=Perl+Dancer',
        'hash=2',
        'hash=4',
        'int1=1',
        'int2=0'));

    my $expected_params = {
        'name' => 'Alexis Sukrieh',
        'IRC Nickname' => 'sukria',
        'Project' => 'Perl Dancer',
        'hash' => [2, 4],
        int1 => 1,
        int2 => 0,
    };

    my $req = Dancer::Request->new(\%ENV);
    is $req->path, '/', 'path is set';
    is $req->method, 'GET', 'method is set';

    is_deeply scalar($req->params), $expected_params, 'params are OK';
    is $req->params->{'name'}, 'Alexis Sukrieh', 'params accessor works';

    my %params = $req->params;
    is_deeply scalar($req->params), \%params, 'params wantarray works';
}
