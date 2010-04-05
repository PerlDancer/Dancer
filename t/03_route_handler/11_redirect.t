use strict;
use warnings;
use Test::More 'no_plan', import => ['!pass'];

use t::lib::TestUtils;
use Dancer ':syntax';
use Dancer::Logger;
use File::Temp qw/tempdir/;

my $dir = tempdir(CLEAN_UP => 1);
set appdir => $dir;
Dancer::Logger->init('File');

get '/' => sub { 'home' };
get '/bounce' => sub { redirect '/' };

my $res = get_response_for_request(GET => '/');
ok(defined($res), "got response for /");
is($res->{content}, "home", 
    "response content for / looks good");

$res = get_response_for_request(GET => '/bounce');

ok(defined($res), "got response for /bounce");
is($res->{status}, 302, 
    "response status is 302 for /bounce");

$res = get_response_for_request(GET => '/');
ok(defined($res), "still got response for /");
is($res->{content}, "home", 
    "response content for / looks good after a redirect");


get '/redirect' => sub { header 'X-Foo' => 'foo'; redirect '/'; };

$ENV{HTTP_HOST} = 'localhost';
$ENV{'psgi.url_scheme'} = 'http';
$res = get_response_for_request(GET => '/redirect');
my %headers = @{$res->{headers}};
is $headers{'X-Foo'},    'foo', 'header x-foo is set';
is $headers{'Location'},
  'http://localhost/', 'location is set to http://localhost/';

get '/redirect_querystring' => sub { redirect '/login?failed=1' };

$res = get_response_for_request( GET => '/redirect_querystring' );
%headers = @{$res->{headers}};

is $headers{'Location'},
   'http://localhost/login?failed=1',
   'location is set to /login?failed=1';
