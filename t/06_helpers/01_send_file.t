use Test::More import => ['!pass'];
use File::Spec;
use lib File::Spec->catdir( 't', 'lib' );
use TestUtils;
use Dancer ':syntax';
use Dancer::FileUtils 'read_glob_content';
use Dancer::Test;

set public => path(dirname(__FILE__), 'public');

plan tests => 6;

ok(get('/cat/:file', sub {
    send_file(params->{file});
}), '/cat/:file route defined');

get '/catheader/:file' => sub {
    header 'FooHeader' => 42;
    send_file(params->{file});
};

my $resp = dancer_response(GET => '/cat/file.txt');
ok(defined($resp), "route handler found for /cat/file.txt");
my %headers = @{$resp->headers_to_array};
is($headers{'Content-Type'}, 'text/plain', 'mime_type is kept');
is(ref($resp->{content}), 'GLOB', "content is a File handle");
my $content = read_glob_content($resp->{content});
$content =~ s/\r//g;
is_deeply( [split(/\n/, $content)], [1,2,3], 'send_file worked as expected');

# now make sure we keep headers
$resp = dancer_response(GET => '/catheader/file.txt');
%headers = @{$resp->headers_to_array};
is $headers{FooHeader}, 42, 'FooHeader is kept';

