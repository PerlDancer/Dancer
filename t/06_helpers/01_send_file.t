use Test::More import => ['!pass'];
use File::Spec;
use lib File::Spec->catdir( 't', 'lib' );
use TestUtils;
use Dancer ':syntax';
use Dancer::FileUtils 'read_glob_content';
use Dancer::Test;
use File::Temp;
use MIME::Types;

set public => path(dirname(__FILE__), 'public');

plan tests => 25;

get '/cat/:file' => sub {
    send_file(params->{file});
    # The next line is not executed, as 'send_error' breaks the route workflow
    die;
};

get '/catheader/:file' => sub {
    header 'FooHeader' => 42;
    send_file(params->{file}, filename => 'header.foo');
};

get '/scalar/file' => sub {
    my $data = 'FOObar';
    send_file( \$data, content_type => 'text/plain', filename => 'foo.bar');
};

get '/as_png/:file' => sub {
    send_file(params->{file}, content_type => 'png');
};

get '/absolute/:file' => sub {
    send_file(path(dirname(__FILE__), "routes.pl"), system_path => 1);
};

get '/absolute/content_type/:file' => sub {
    send_file(path(dirname(__FILE__), "routes.pl"), system_path => 1, content_type => 'text/plain');
};

get '/custom_status' => sub {
    status 'not_found';
    send_file('file.txt');
};

get '/ioscalar' => sub {
    send_file(IO::Scalar->new(\ "IO::Scalar content"), filename => 'ioscalar');
};

my ($temp_fh, $temp_filename) = File::Temp::tempfile('dancer-tests-XXXX',
                                                     TMPDIR => 1, UNLINK => 1);
$temp_fh->print("hello world\n");
$temp_fh->close;

get '/404_with_filename' => sub {
    send_file($temp_filename, filename => 'foo.bar');
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
is(
    $headers{'Content-Disposition'}, 
    'attachment; filename="header.foo"', 
    'Content-Disposition header contains expected filename'
);

my $png = dancer_response(GET => '/as_png/file.txt');
ok(defined($png), "route handler found for /as_png/file.txt");
my %png_headers = @{$png->headers_to_array};
is($png_headers{'Content-Type'}, 'image/png', 'mime_type can be forced');


$resp = undef; # just to be sure
$resp = dancer_response(GET => '/absolute/file.txt');
ok(defined($resp), "route handler found for /absolute/file.txt");
%headers = @{$resp->headers_to_array};

# With hash randomization, .pl can be either text/perl or
# application/perl. This is determined by MIME::Types.
my $perl_mime = MIME::Types->new->mimeTypeOf('pl');
is($headers{'Content-Type'}, $perl_mime, 'mime_type is ok');

is(ref($resp->{content}), 'GLOB', "content is a File handle");
$content = read_glob_content($resp->{content});
like($content, qr/'foo loaded'/, "content is ok");

$resp = undef; # just to be sure
$resp = dancer_response(GET => '/absolute/content_type/file.txt');
%headers = @{$resp->headers_to_array};
is($headers{'Content-Type'}, 'text/plain', 'mime_type is ok');

$resp = undef; # just to be sure
$resp = dancer_response(GET => '/scalar/file');
ok(defined($resp), "route handler found for /scalar/file");
%headers = @{$resp->headers_to_array};
is($headers{'Content-Type'}, 'text/plain', 'mime_type is ok');
is(
    $headers{'Content-Disposition'}, 
    'attachment; filename="foo.bar"',
    'Content-Disposition hedaer contains expected filename'
);
$content = $resp->{content};
like($content, qr/FOObar/, "content is ok");

$resp = undef; # just to be sure
$resp = dancer_response(GET => '/custom_status');
ok(defined($resp), "route handler found for /custom_status");
is(  $resp->{status},  404,       "Status 404 for /custom_status");
is(ref($resp->{content}), 'GLOB', "content is a filehandle");
$content = read_glob_content($resp->{content});
$content =~ s/\r//g;
is_deeply( [split(/\n/, $content)], [1,2,3], 'send_file worked as expected');

SKIP: {
    skip "Need IO::Scalar", 2
        unless Dancer::ModuleLoader->load('IO::Scalar');

    $resp = undef; # just to be sure
    $resp = dancer_response(GET => '/ioscalar');
    ok(defined($resp), "/ioscalar gave us a response");
    is($resp->{content}, "IO::Scalar content", "Got correct content from IO::Scalar");
}

# This snippet fixes #912
$resp = undef;
$resp = dancer_response(GET => '/404_with_filename');
ok(defined($resp), "route handler found for /404_with_filename");
is($resp->{status}, 404, "Status 404 for /404_with_filename");
