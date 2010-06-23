use Test::More;
use strict;
use warnings;
use Dancer::ModuleLoader;
use Dancer::Config 'setting';
use File::Path qw/mkpath/;
use File::Temp qw/tempdir/;
use File::Slurp qw/write_file/;

plan skip_all => "LWP is needed for this test"
    unless Dancer::ModuleLoader->load('LWP::UserAgent');
plan skip_all => "Test::TCP is needed for this test"
    unless Dancer::ModuleLoader->load("Test::TCP");
plan skip_all => "Module::Refresh is needed for this test"
    unless Dancer::ModuleLoader->load("Module::Refresh");

plan tests => 4;

my $dir = tempdir(CLEANUP => 1);
my $fulldir = "$dir/t/lib";
ok(mkpath($fulldir), "Made temp lib dir $fulldir");

my $orig_str = 'Hello, this is the home';
my $new_str = 'Goodbye, that was it';

write_package($orig_str, $fulldir);
push @INC, $dir;
require_ok("$fulldir/RouteRefresh.pm");

Test::TCP::test_tcp(
    client => sub {
        my $port = shift;
        my $ua = LWP::UserAgent->new;

        my $res = $ua->get("http://127.0.0.1:$port/");
        is $res->content, $orig_str, 'Original route correct';

        write_package($new_str, $dir);

        $res = $ua->get("http://127.0.0.1:$port/");
        is $res->content, $new_str, 'Updated route refreshed';
    },
    server => sub {
        my $port = shift;

        Dancer::Config->load;
        setting environment => 'production';
        setting access_log => 0;
        setting port => $port;
        setting auto_refresh => 1;
        Dancer->dance();
    },
);

sub write_package {
    my $msg = shift;
    my $dir = shift;

    write_file "$dir/RouteRefresh.pm", <<"EOF";
package t::lib::RouteRefresh;
use Dancer;
get '/' => sub { "$msg" };
1;
EOF
}
