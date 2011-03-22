use Test::More import => ['!pass'];
use File::Spec;
use lib File::Spec->catdir( 't', 'lib' );
use TestUtils;
use Dancer ':syntax';
use Dancer::FileUtils 'read_glob_content';
use Dancer::Test;

plan tests => 7;

ok(get('/cat/:file', sub {
    send_any_file( path(dirname(__FILE__), "routes.pl"));
}), '/cat/:file route defined');

get '/as_png/:file' => sub {
    send_any_file( path(dirname(__FILE__), "routes.pl"), content_type => 'png');
};

my $resp = dancer_response(GET => '/cat/file.txt');
ok(defined($resp), "route handler found for /cat/file.txt");
my %headers = @{$resp->headers_to_array};
is($headers{'Content-Type'}, 'application/x-perl', 'mime_type is kept');
is(ref($resp->{content}), 'GLOB', "content is a File handle");
my $content = read_glob_content($resp->{content});
like($content, qr/foo loaded/, "have the expected contents");

my $png = dancer_response(GET => '/as_png/file.txt');
ok(defined($png), "route handler found for /as_png/file.txt");
my %png_headers = @{$png->headers_to_array};
is($png_headers{'Content-Type'}, 'image/png', 'mime_type can be forced');
