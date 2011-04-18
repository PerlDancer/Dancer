use Dancer ':tests';
use Test::More;

use Dancer::Test;

plan tests => 3;

get '/foo/**'   => sub { show_splat() };
response_content_is [ GET => '/foo/a/b/c' ] => '(a,b,c)';

get '/bar/*/**' => sub { show_splat() };
response_content_is [ GET => '/bar/a/b/c' ] => 'a:(b,c)';

get '/alpha/**/gamma' => sub { show_splat() };
response_content_is [ GET => '/alpha/beta/delta/gamma' ] => '(beta,delta)';

sub show_splat {
    return join ':', map { ref $_ ? "(" . join( ',', @$_ ) . ")": $_ } splat;
}
