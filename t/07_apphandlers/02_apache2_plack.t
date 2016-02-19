# simulate an Apache2 + Plack environment
use strict;
use warnings;

use Test::More import => ['!pass'];

plan skip_all => "Plack is needed for this test"
    unless Dancer::ModuleLoader->load('Plack::Request');

plan tests => 2;

use Dancer::Handler::PSGI;

use File::Spec;
use Dancer::Request;

my $request = {};
my $env = {};

my $document_root = File::Spec->rel2abs('.');
my $server_name = 'localhost.localdomain';
my $remote_addr = '127.0.0.1';
my $server_admin = 'admin@domain.com';
my $server_addr = '127.0.0.1';
my $host_name = 'app.localdomain.com';

# a / request
$request->{'/'} = Dancer::Request->new_for_request(GET => '/');

$env->{'/'}  = {
                 'psgi.multiprocess' => 1,
                 'SCRIPT_NAME' => '/',
                 'HTTP_ACCEPT' => 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
                 'REQUEST_METHOD' => 'GET',
                 'psgi.multithread' => '',
                 'SCRIPT_FILENAME' => '/srv/twitter-karma.sukria.net/public/',
                 'SERVER_SOFTWARE' => 'Apache/2.2.9 (Debian) PHP/5.2.6-1+lenny3 with Suhosin-Patch mod_python/3.3.1 Python/2.5.2 Phusion_Passenger/2.0.3 mod_perl/2.0.4 Perl/v5.10.0',
                 'HTTP_USER_AGENT' => 'Mozilla/5.0 (X11; U; Linux i686; fr; rv:1.9.0.13) Gecko/2009080315 Ubuntu/9.04 (jaunty) Firefox/3.0.13',
                 'REMOTE_PORT' => '33677',
                 'QUERY_STRING' => '',
                 'SERVER_SIGNATURE' => '<address>Apache/2.2.9 (Debian) PHP/5.2.6-1+lenny3 with Suhosin-Patch mod_python/3.3.1 Python/2.5.2 Phusion_Passenger/2.0.3 mod_perl/2.0.4 Perl/v5.10.0 Server at k.sukria.net Port 80</address>
',
                 'HTTP_CACHE_CONTROL' => 'max-age=0',
                 'HTTP_ACCEPT_LANGUAGE' => 'en-us,fr;q=0.8,fr-fr;q=0.5,en;q=0.3',
                 'HTTP_KEEP_ALIVE' => '300',
                 'MOD_PERL_API_VERSION' => '2',
                 'PATH' => '/usr/local/bin:/usr/bin:/bin',
                 'GATEWAY_INTERFACE' => 'CGI/1.1',
                 'psgi.version' => [ 1, 0 ],
                 'DOCUMENT_ROOT' => $document_root,
                 'psgi.run_once' => '',
                 'SERVER_NAME' => $server_name,
                 'SERVER_ADMIN' => $server_admin,
                 'HTTP_ACCEPT_ENCODING' => 'gzip,deflate',
                 'HTTP_CONNECTION' => 'keep-alive',
                 'HTTP_ACCEPT_CHARSET' => 'ISO-8859-1,utf-8;q=0.7,*;q=0.7',
                 'SERVER_PORT' => '80',
                 'REMOTE_ADDR' => $remote_addr,
                 'SERVER_PROTOCOL' => 'HTTP/1.1',
                 'REQUEST_URI' => '/',
                 'psgi.errors' => *::STDERR,
                 'SERVER_ADDR' => $server_addr,
                 'psgi.url_scheme' => 'http',
                 'HTTP_HOST' => $host_name,
                 };

use Dancer;

set apphandler => 'PSGI', logger => 'file';

Dancer::Config->load;

get '/'    => sub { '/'    };
get '/foo' => sub { '/foo' };

my $req = $request->{'/'};
my $handler = Dancer::Handler::PSGI->new;
my $resp = $handler->handle_request($req);

ok(defined($resp), 'handle_request responded');
is($resp->[0], 200, 'status is 200 OK');
