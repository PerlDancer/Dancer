use Dancer ':tests';
use Test::More;

use Dancer::Test;

plan tests => 6;

get '/foo/**'   => sub { show_splat() };
response_content_is [ GET => '/foo/a/b/c' ] => '(a,b,c)';

get '/bar/*/**' => sub { show_splat() };
response_content_is [ GET => '/bar/a/b/c' ] => 'a:(b,c)';

get '/alpha/**/gamma' => sub { show_splat() };
response_content_is [ GET => '/alpha/beta/delta/gamma' ] => '(beta,delta)';
response_content_is [ GET => '/alpha/beta/gamma' ] => '(beta)';

# mixed tokens and splat
my $route_code = sub {
    my $id = param 'id';
    $id = 'undef' unless defined $id;
    my $splt = show_splat();
    return "$id:$splt"
};
get '/some/:id/**/*' => $route_code;
response_content_is [ GET => '/some/where/to/run/and/hide' ] => 'where:(to,run,and):hide';

get '/some/*/**/:id?' => $route_code;
response_content_is [ GET => '/some/one/to/say/boo/' ] => 'undef:one:(to,say,boo)';

sub show_splat {
    return join ':', map { ref $_ ? "(" . join( ',', @$_ ) . ")": $_ } splat;
}
