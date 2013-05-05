#!/usr/bin/perl 

use 5.16.0;

use strict;
use warnings;

use Git::Repository;
use List::AllUtils qw/ uniq after before_incl /;
use Path::Tiny;
use List::Pairwise qw/ mapp /;

my $git = Git::Repository->new( work_tree => '.' );

my %new_authors = map { split '!' } $git->run( 'log', '--format=%an!%ae',
    '28dff7d15cafa93..perldancer/devel' );

my $file = path('AUTHORS');

delete $new_authors{$_} for map { /(\S.*?)\s+</ } $file->lines;

my @contributors = (
    map( { /    (.*)/ } after { /\[ CONTRIBUTORS \]/ } $file->lines ),
    mapp { "$a <$b>" } %new_authors );

my @lines = before_incl { /\[ CONTRIBUTORS \]/ } $file->lines;
push @lines, "\n",
             map( { "    $_\n" } sort { lc($a) cmp lc($b) } @contributors ),
             "\n";

$file->spew(@lines);
