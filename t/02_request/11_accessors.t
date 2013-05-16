use Test::More tests => 15;

use strict;
use warnings;
use Dancer::Request;

my $env = {
    'REQUEST_METHOD'  => 'GET',
    'PATH_INFO'       => '/',
    'REQUEST_URI'     => '/',
    'CONTENT_TYPE'    => 'text/plain',
    'REMOTE_ADDR'     => '192.168.0.2',
    'CONTENT_LENGTH'  => 42,
    'X_FORWARDED_FOR' => '192.168.0.3',
    'HTTP_USER_AGENT' => 'Mozy',
    'HTTP_HOST'       => 'foo.bar.com',
    'REMOTE_USER'     => 'franck',
    'REQUEST_BASE'    => '/app-root',
};

my $r = Dancer::Request->new(env => $env);
is_deeply $r->env, $env, "environement looks good";

is $r->path, $env->{PATH_INFO}, 'path looks good';
is $r->method, $env->{REQUEST_METHOD}, 'method looks good';
is $r->content_type, $env->{CONTENT_TYPE}, 'content_type looks good';
is $r->content_length, $env->{CONTENT_LENGTH}, 'content_length looks good';
is $r->body, '', 'body looks good';
is $r->user_agent, 'Mozy', 'user_agent looks good';
is $r->agent, 'Mozy', 'agent looks good';
is $r->host, 'foo.bar.com', 'host looks good';
is $r->remote_address, '192.168.0.2', 'remote address looks good';
is $r->forwarded_for_address, '192.168.0.3', 'forwarded address looks good';
is $r->user, 'franck',  'remote user looks good';
is $r->request_uri, '/', 'request_uri looks good';
is $r->uri, $r->request_uri, '->uri is an alis on ->request_uri';
is $r->request_base, '/app-root', 'request_base looks good';
