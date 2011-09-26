use strict;
use warnings;

use Test::More import => ['!pass'];
use Dancer ':syntax';
use Dancer::Test;
use Dancer::FileUtils 'read_glob_content';

plan skip_all => "File::Temp 0.22 required"
    unless Dancer::ModuleLoader->load( 'File::Temp', '0.22' );

plan tests => 5;

my $dir = File::Temp::tempdir( CLEANUP => 1 );

setting public => $dir;

open my $fh, '>', File::Spec->catfile( $dir, 'test.txt' );
print $fh "this is content";
close $fh;

ok(
    hook 'before_file_render' => sub {
        my $file_path = shift;
        $file_path =~ s/foo/test.txt/;
    }
);

ok(
    hook 'after_file_render' => sub {
        my $response = shift;
        is       $response->header('Content-Type'), 'text/plain';
       $response->header( 'Content-Type' => 'text/tests' );
    }
);

get '/' => sub {
     send_file('test.txt') 
};

my $response = dancer_response( GET => '/' );
is read_glob_content( $response->content ), 'this is content';
is $response->header('Content-Type'), 'text/tests';

