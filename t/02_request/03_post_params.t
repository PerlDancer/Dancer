use Test::More tests => 6;

use strict;
use warnings FATAL => 'all';
use Dancer::Request;
use Dancer::FileUtils 'path', 'dirname';
use IO::File;

$ENV{REQUEST_METHOD} = 'POST';
$ENV{PATH_INFO} = '/';

my $fixture_input = path(dirname(__FILE__), 'input.data');
my $fixture_fh = IO::File->new($fixture_input, "r", O_BINARY) 
    or die "couldnot open fixture input : $!";

$ENV{'psgi.input'} = $fixture_fh;
$ENV{CONTENT_LENGTH} = 34;

my $expected_params = {
    name => 'john',
    email => "johonny\@gmail.com\n",
};

my $req = Dancer::Request->new;
is $req->path, '/', 'path is set';
is $req->method, 'POST', 'method is set';
is_deeply $req->input_handle, $fixture_fh, 'input handle is ok';

is_deeply scalar($req->params), $expected_params, 'params are OK';
is $req->params->{'name'}, 'john', 'params accessor works';

my %params = $req->params;
is_deeply scalar($req->params), \%params, 'params wantarray works';

