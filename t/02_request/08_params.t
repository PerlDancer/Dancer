use Test::More tests => 26;
use strict;
use warnings FATAL => 'all';
use Dancer::Request;

{
    # 1. - get params

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
                                   'int2=0',
                                   'url=http://foo.com/?bar=biz'));

        my $expected_params = {
                               'name' => 'Alexis Sukrieh',
                               'IRC Nickname' => 'sukria',
                               'Project' => 'Perl Dancer',
                               'hash' => [2, 4],
                               int1 => 1,
                               int2 => 0,
                               url => 'http://foo.com/?bar=biz',
                              };

        my $req = Dancer::Request->new(env => \%ENV);
        is $req->path, '/', 'path is set';
        is $req->method, 'GET', 'method is set';
        ok $req->is_get, "request method is GET";
        is_deeply scalar($req->params), $expected_params, 'params are OK';
        is_deeply scalar($req->Vars), $expected_params, 'params are OK (using Vars)';
        is $req->params->{'name'}, 'Alexis Sukrieh', 'params accessor works';

        my %params = $req->params;
        is_deeply scalar($req->params), \%params, 'params wantarray works';
    }
}

{
    # 2. - post params
    my $body = 'foo=bar&name=john&hash=2&hash=4&hash=6&';
    open my $in, '<', \$body;

    my $env = {
               CONTENT_LENGTH => length($body),
               CONTENT_TYPE   => 'application/x-www-form-urlencoded',
               REQUEST_METHOD => 'POST',
               SCRIPT_NAME    => '/',
               'psgi.input'   => $in,
              };

    my $expected_params = {
                           name => 'john',
                           foo  => 'bar',
                           hash => [2, 4, 6],
                          };

    my $req = Dancer::Request->new(env => $env);
    is $req->path, '/', 'path is set';
    is $req->method, 'POST', 'method is set';
    ok $req->is_post, 'method is post';
    my $request_to_string = $req->to_string;
    like $request_to_string, qr{\[#\d+\] POST /};

    is_deeply scalar($req->params), $expected_params, 'params are OK';
    is $req->params->{'name'}, 'john', 'params accessor works';

    my %params = $req->params;
    is_deeply scalar($req->params), \%params, 'params wantarray works';

}

{
    # 3. - mixed params
    my $body = 'x=1&meth=post';
    open my $in, '<', \$body;

    my $env = {
               CONTENT_LENGTH => length($body),
               CONTENT_TYPE   => 'application/x-www-form-urlencoded',
               QUERY_STRING   => 'y=2&meth=get',
               REQUEST_METHOD => 'POST',
               SCRIPT_NAME    => '/',
               'psgi.input'   => $in,
              };

    my $mixed_params = {
                        meth => 'post',
                        x => 1,
                        y => 2,
                       };

    my $get_params = {
                      y => 2,
                      meth => 'get',
                     };

    my $post_params = {
                       x => 1,
                       meth => 'post',
                      };

    my $req = Dancer::Request->new(env => $env);
    is $req->path, '/', 'path is set';
    is $req->method, 'POST', 'method is set';

    is_deeply scalar($req->params), $mixed_params, 'params are OK';
    is_deeply scalar($req->params('body')), $post_params, 'body params are OK';
    is_deeply scalar($req->params('query')), $get_params, 'query params are OK';
}
