use strict;
use warnings;
use Test::More tests => 9, import => ['!pass'];

use Dancer ':syntax';
use Dancer::Test;

ok(get(qr{/hello/([\w]+)} => sub { [splat] }), 'first route set');
ok(get(qr{/show/([\d]+)} => sub { [splat] }), 'second route set');
ok(get(qr{/post/([\w\d\-\.]+)/#comment([\d]+)} => sub { [splat] }), 'third route set');

my @tests = ( 
    {path => '/hello/sukria', 
     expected => ['sukria']},

    {path => '/show/245', 
     expected => ['245']},

    {path => '/post/this-how-to-write-smart-webapp/#comment412',
     expected => ['this-how-to-write-smart-webapp', '412']},
);

foreach my $test (@tests) {
    my $handle;
    my $path = $test->{path};
    my $expected = $test->{expected};
 
    my $request = [GET => $path];
       
    response_exists($request, "route handler found for path `$path'");
    response_content_is_deeply($request, $expected, 
        "match data for path `$path' looks good");
}
