use Test::More;
use Dancer ':tests', ':syntax';
use Dancer::Test;

plan tests => 20;

# basic redirect
{
    get '/'         => sub { 'home' };
    get '/bounce'   => sub { redirect '/' };
    get '/redirect' => sub { header 'X-Foo' => 'foo'; redirect '/'; };
    get '/redirect_querystring' => sub { redirect '/login?failed=1' };

    response_exists [ GET => '/' ];
    response_content_is [ GET => '/' ], "home";

    response_exists [ GET => '/bounce' ];
    response_status_is [ GET => '/bounce' ], 302;

    response_exists [ GET => '/' ];
    response_content_is [ GET => '/' ], "home";

    my $expected_headers = [
        'Location'     => 'http://localhost/',
        'Content-Type' => 'text/html',
        'X-Foo'        => 'foo',
    ];
    response_headers_include [ GET => '/redirect' ] => $expected_headers;

    $expected_headers = [
        'Location'     => 'http://localhost/login?failed=1',
        'Content-Type' => 'text/html',
    ];
    response_headers_include [ GET => '/redirect_querystring' ] =>
      $expected_headers;
}

# redirect absolute
{
    get '/absolute_with_host' => sub { redirect "http://foo.com/somewhere"; };
    get '/absolute' => sub { redirect "/absolute"; };
    get '/relative' => sub { redirect "somewhere/else"; };

    my $res = dancer_response GET => '/absolute_with_host';
    is $res->header('Location') => 'http://foo.com/somewhere';

    $res = dancer_response GET => '/absolute';
    is $res->header('Location') => 'http://localhost/absolute';

    $res = dancer_response GET => '/relative';
    is $res->header('Location') => 'http://localhost/somewhere/else';
}

# redirect no content
{

    my $not_redirected_content = 'gotcha';
    get '/home' => sub { "home"; };

    get '/cond_bounce' => sub {
        if ( params->{'bounce'} ) {
            redirect '/';
            return;
        }
        $not_redirected_content;
    };

    my $req = [ GET => '/cond_bounce', { params => { bounce => 1 } } ];
    response_exists $req,     "response for /cond_bounce, with bounce param";
    response_status_is $req,  302, 'status is 302';
    response_content_is $req, '', 'content is empty when bounced';

    $req = [ GET => '/cond_bounce' ];
    response_exists $req,     "response for /cond_bounce without bounce param";
    response_status_is $req,  200, 'status is 200';
    response_content_is $req, $not_redirected_content, 'content is not empty';

}

# redirect behind proxy
{
    set behind_proxy => 1;
    $ENV{X_FORWARDED_HOST} = "nice.host.name";
    response_headers_include [GET => '/bounce'] => [Location => 'http://nice.host.name/'],
      "Test X_FORWARDED_HOST";

    $ENV{HTTP_FORWARDED_PROTO} = "https";
    response_headers_include [GET => '/bounce'] => [Location => 'https://nice.host.name/'],
      "Test HTTP_FORWARDED_PROTO";

    $ENV{X_FORWARDED_PROTOCOL} = "ftp";  # stupid, but why not?
    response_headers_include [GET => '/bounce'] => [Location => 'ftp://nice.host.name/'],
      "Test X_FORWARDED_PROTOCOL";
}
