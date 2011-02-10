use strict;
use warnings;
use Test::More tests => 10, import => ['!pass'];

use Dancer ':syntax';
use Dancer::Logger;
use File::Temp qw/tempdir/;
use Dancer::Test;

my $dir = tempdir(CLEANUP => 1);
set appdir => $dir;
Dancer::Logger->init('File');

# checking get

get '/'        => sub { 'home' };
get '/bounce/' => sub {
    return forward('/');
};

response_exists     [ GET => '/' ];
response_content_is [ GET => '/' ], 'home';

response_exists     [ GET => '/bounce/' ];
response_content_is [ GET => '/bounce/' ], 'home';

my $expected_headers = [
    'Content-Type' => 'text/html',
    'X-Powered-By' => "Perl Dancer ${Dancer::VERSION}",
];

response_headers_are_deeply [ GET => '/bounce/' ], $expected_headers;

# checking post

post '/'        => sub { 'post-home' };
post '/bounce/' => sub {
    return forward('/');
};

response_exists     [ POST => '/' ];
response_content_is [ POST => '/' ], 'post-home';

response_exists     [ POST => '/bounce/' ];
response_content_is [ POST => '/bounce/' ], 'post-home';

response_headers_are_deeply [ POST => '/bounce/' ], $expected_headers;

Dancer::Logger::logger->{fh}->close;
File::Temp::cleanup();

