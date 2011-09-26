use Test::More 'tests' => 1, import => ['!pass'];
use strict;
use warnings;
use utf8;
use File::Spec;

use Dancer ':syntax';
use Dancer::Test;

my $file = path(dirname(__FILE__), "public", "utf8file.txt");

get "/hello" => sub {
    open my $f, "<:utf8", $file;
    chomp(my $line = <$f>);
    $line =~ s/ //g;
    close $f;
    $line
};

response_content_is [GET => "/hello"] => "⋄⋄⋄Hello⋄⋄⋄";
