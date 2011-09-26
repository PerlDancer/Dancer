use strict;
use warnings;
    
use Dancer ':syntax';
use Dancer::Request;
use Dancer::Test;
use Dancer::FileUtils;
use Test::More 'import' => ['!pass'];

plan skip_all => "File::Temp 0.22 required"
    unless Dancer::ModuleLoader->load( 'File::Temp', '0.22' );

sub test_path {
    my ($file, $dir) = @_;
    is dirname($file), $dir, "dir of $file is $dir";
}

my $filename = "some_\x{1A9}_file.txt";

my $content = qq{------BOUNDARY
Content-Disposition: form-data; name="test_upload_file"; filename="$filename"
Content-Type: text/plain

SHOGUN
------BOUNDARY
Content-Disposition: form-data; name="test_upload_file"; filename="yappo2.txt"
Content-Type: text/plain

SHOGUN2
------BOUNDARY
Content-Disposition: form-data; name="test_upload_file3"; filename="yappo3.txt"
Content-Type: text/plain

SHOGUN3
------BOUNDARY
Content-Disposition: form-data; name="test_upload_file4"; filename="yappo4.txt"
Content-Type: text/plain

SHOGUN4
------BOUNDARY
Content-Disposition: form-data; name="test_upload_file4"; filename="yappo5.txt"
Content-Type: text/plain

SHOGUN4
------BOUNDARY
Content-Disposition: form-data; name="test_upload_file6"; filename="yappo6.txt"
Content-Type: text/plain

SHOGUN6
------BOUNDARY--
};
$content =~ s/\r\n/\n/g;
$content =~ s/\n/\r\n/g;

plan tests => 21;

do {
    open my $in, '<', \$content;
    my $req = Dancer::Request->new(
       env => {
               'psgi.input'   => $in,
               CONTENT_LENGTH => length($content),
               CONTENT_TYPE   => 'multipart/form-data; boundary=----BOUNDARY',
               REQUEST_METHOD => 'POST',
               SCRIPT_NAME    => '/',
               SERVER_PORT    => 80,
              }
    );
    Dancer::SharedData->request($req);

    my @undef = $req->upload('undef');
    is @undef, 0, 'non-existent upload as array is empty';
    my $undef = $req->upload('undef');
    is $undef, undef, '... and non-existent upload as scalar is undef';

    my @uploads = upload('test_upload_file');
    like $uploads[0]->content, qr|^SHOGUN|,
      "content for first upload is ok, via 'upload'";
    like $uploads[1]->content, qr|^SHOGUN|, "... content for second as well";
    is $req->uploads->{'test_upload_file4'}[0]->content, 'SHOGUN4',
      "... content for other also good";

    note "headers";
    is_deeply $uploads[0]->headers, {
        'Content-Disposition' => qq[form-data; name="test_upload_file"; filename="$filename"],
        'Content-Type'        => 'text/plain',
    };

    note "type";
    is $uploads[0]->type, 'text/plain';

    my $test_upload_file3 = $req->upload('test_upload_file3');
    is $test_upload_file3->content, 'SHOGUN3',
      "content for upload #3 as a scalar is good, via req->upload";

    my @test_upload_file6 = $req->upload('test_upload_file6');
    is $test_upload_file6[0]->content, 'SHOGUN6',
      "content for upload #6 is good";

    my $upload = $req->upload('test_upload_file6');
    isa_ok $upload, 'Dancer::Request::Upload';
    is $upload->filename, 'yappo6.txt', 'filename is ok';
    ok $upload->file_handle, 'file handle is defined';
    is $req->params->{'test_upload_file6'}, 'yappo6.txt',
      "filename is accessible via params";

    # copy_to, link_to
    my $dest_dir = File::Temp::tempdir(CLEANUP => 1, TMPDIR => 1);
    my $dest_file = File::Spec->catfile( $dest_dir, $upload->basename );
    $upload->copy_to($dest_file);
    ok( ( -f $dest_file ), "file '$dest_file' has been copied" );

    my $dest_file_link = File::Spec->catfile( $dest_dir, "hardlink" );
    $upload->link_to( $dest_file_link );
    ok( ( -f $dest_file_link ), "hardlink '$dest_file_link' has been created" );

    # make sure cleanup is performed when the HTTP::Body object is purged
    my $file = $upload->tempname;
    ok( ( -f $file ), 'temp file exists while HTTP::Body lives' );
    undef $req->{_http_body};
    SKIP: {
        skip "Win32 can't remove file/link while open, deadlock with HTTP::Body", 1 if ($^O eq 'MSWin32');
        ok( ( !-f $file ), 'temp file is removed when HTTP::Body object dies' );
    }

    unlink($file) if ($^O eq 'MSWin32');
};

# test with Dancer::Test
my $dest_dir = File::Temp::tempdir(CLEANUP => 1, TMPDIR => 1);
my $dest_file = File::Spec->catfile( $dest_dir, 'foo' );

post(
    '/upload',
    sub {
        my $file = upload('test');
        is $file->{filename}, $dest_file;
        return $file->content;
    }
);

post(
    '/uploads',
    sub {
        my $content;
        my $uploads = request->uploads;
        foreach my $u (keys %$uploads){
            $content .= $uploads->{$u}->content;
        }
        return $content;
    }
);

$content = "foo";
open my $fh, '>', $dest_file;
print $fh $content;
close $fh;

my $resp =
  dancer_response( 'POST', '/upload',
    { files => [ { name => 'test', filename => $dest_file } ] } );
is $resp->content, $content;

my $files;
for (qw/a b c/){
    my $dest_file = File::Spec->catfile( $dest_dir, $_ );
    open my $fh, '>', $dest_file;
    print $fh $_;
    close $fh;
    push @$files, {name => $_, filename => $dest_file};
}

$resp =  dancer_response( 'POST', '/uploads', {files => $files});
is length($resp->content), 3;
like $resp->content, qr/a/;
