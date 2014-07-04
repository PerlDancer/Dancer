use Test::More import => ['!pass'];
use Dancer ':syntax';
use Dancer::Test;
use Dancer::Route;

my @tests = (
    { path => '/capture/test/foo',         expected => 'capture foo: test' },
    { path => '/capture/test/',            expected => 'capture root: test' },
    { path => '/capture/another_test',     expected => 'capture root: another_test' },

    { path => '/regex/test2/bar',     expected => 'regex bar: test2' },
    { path => '/regex/test2/',     expected => 'regex root: test2' },
    { path => '/regex/test2_again',     expected => 'regex root: test2_again' },

    { path => '/nested/capture/test3/baz',         expected => 'capture baz: test3' },

    # This is a bug, as Dancer::Route::_init_prefix() doesn't detect this as a regex,
    #  so the capture doesn't happen
    #{ path => '/nested/regex/test3/quxx',         expected => 'regex quxx: test3' },
);

plan tests => 2*@tests;

{
    prefix '/capture/:word' => sub {
      get '/foo'  => sub { 'capture foo: '  . params->{word} };
      get '/'     => sub { 'capture root: ' . params->{word} };
    };

    #get '/bar'  => sub { 'regex bar: '  . join ',', splat };

    prefix qr{/regex/([\w]+)} => sub {
      get '/bar'  => sub { 'regex bar: '  . join ',', splat };
      get '/'     => sub { 'regex root: ' . join ',', splat };
    };

    prefix '/nested' => sub {
        prefix '/capture/:word' => sub {
            get '/baz'  => sub { 'capture baz: '  . params->{word} };
        };

        prefix qr{/regex/([\w]+)} => sub {
            get '/quxx'  => sub { 'regex quxx: '  . join ',', splat };
        };
    }
}

foreach my $test (@tests) {
    my $path     = $test->{path};
    my $expected = $test->{expected};

    response_status_is         [GET => $path] => 200;
    response_content_is_deeply [GET => $path] => $expected;
}

