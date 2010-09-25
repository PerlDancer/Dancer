#!/usr/bin/perl

use strict;
use warnings;

open FILE, $ARGV[0] or die $!;

my $data = '';
while(<FILE>) {
    $data .= pack('u*', $_);
}
close FILE;

print "$data\n";
