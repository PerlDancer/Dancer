use strict;
use warnings;

use Test::More import => ['!pass'];

unless ( $ENV{RELEASE_TESTING} ) {
    plan( skip_all => "Author tests not required for installation" );
}

#### Change these values if the Changelog syntax changes :

# changelog file name
my $changelog_filename = 'CHANGES';

# don't check for versions older or equal to this
my $stop_checking_version = '1.3060';

# ordered list of possible sections
my @possible_sections = ('SECURITY', 'API CHANGES', 'BUG FIXES', 'ENHANCEMENTS', 'DOCUMENTATION', );

#################


# beware : below are some crazy paranoid testing

my $possible_sections = join('|', @possible_sections);

open(my $fh, '<', $changelog_filename);
my @lines = map { chomp; $_ } <$fh>;

my $tests_count = 0;
while (1) { $lines[$tests_count++] !~ /^\Q$stop_checking_version\E(?:\s|$)/ or last }

# test count = number of lines + 1
plan tests => $tests_count;

my @struct;

{ # start scoping

my $line_nb = 0;
my $line;
sub _consume_line { $line = shift @lines;
                    defined $line or goto END_CHANGES;
                    $line =~ /^\Q$stop_checking_version\E(?:\s|$)/ and goto END_CHANGES;
                    $line_nb++;
                  }
sub _peek_line { $line = $lines[0];
                 defined $line or goto END_CHANGES;
                 $line =~ /^\Q$stop_checking_version\E(?:\s|$)/ and goto END_CHANGES;
               }
sub _fail { fail("changelog error (line $line_nb): " . shift() . " line was : '$line'"); }
sub _fail_bail_out { _fail(@_); BAIL_OUT("changelog is not safe enough to continue checking"); }
sub _pass { Test::More::pass("check line $line_nb"); }

my $current_version;
my $current_version_is_dev;
my $current_section;
my $current_item_start;
my $current_item;

WHERE_NEXT:
_peek_line();
if (defined $current_item || defined $current_item_start) {
    # we can have an item line, a new item start, or a separator
    $line =~ /^\s+\*/  and goto ITEM_START;
    $line =~ /^\s+\S+/ and goto ITEM;
    $line =~ /^\s*$/   and goto SEPARATOR;
    _fail_bail_out("next line doesn't look like an item line, a new item start, or a separator");
}
if (defined $current_section) {
    # we can have an item line, a new item start
    $line =~ /^\s+\*/  and goto ITEM_START;
    $line =~ /^\s+\S+/ and goto ITEM;
    _fail_bail_out("next line doesn't look like an item line, a new item start");
}
if (defined $current_version) {
    # we can have a new section or a new version
    $line =~ /^\s/   and goto SECTION;
    $line =~ /^\S/   and goto VERSION;
    _fail_bail_out("next line doesn't look like a new section or new version");
}
goto VERSION;


SEPARATOR:
# separator
_consume_line();
$line eq '' ? _pass() : _fail_bail_out("should be a separator (empty line)");
$current_section = undef;
$current_item_start = undef;
$current_item = undef;
goto WHERE_NEXT;

VERSION:
# version number
_consume_line();
if ( (my ($pre, $version, $post)) = ($line =~ /^(\s*)(\S.*\S)(\s*)$/)) {
    defined $pre or $pre = '';
    defined $post or $post = '';
    my $lpre = length $pre;
    my $lpost = length $post;
    $lpre and _fail("line starts with $lpre blank caracters, but it should not");
    $lpost and _fail("line ends with $lpre blank caracters, but it should not");
    like($version, qr/^{{\$NEXT}}$|^\d\.\d{4}(_\d{2}   |      )\d{2}.\d{2}.\d{4}$/, "changelog line $line_nb: check version failed");
    $version =~ qr/^({{\$NEXT}})$|^\d\.\d{4}(_\d{2}   |      )\d{2}.\d{2}.\d{4}$/;
#    print STDERR " ------->  [$1] [$2]\n";
    $current_version_is_dev = defined $1 || $2 =~ /^_\d{2}/;

    $current_version = [];
    $current_section = undef;
    $current_item_start = undef;
    $current_item = undef;
    push @struct, { $version => $current_version };
} else {
    _fail("line should contain a version number, but it contains '$line'.");
}
$current_version_is_dev
  and goto SEPARATOR;
goto CODENAME;

CODENAME:
# the codename is not mandatory, but strongly encouraged. So warn if it's not
# there, but don't die
_peek_line();
if ($line =~ /^\s*$/) {
    warn "It's recommended to add a CodeName to stable releases (non-dev versions).\n"
         . "There is no CodeName at line $line_nb. Codename format is : "
         . "    ** Codename: <The Name> // <The person it's dedicated to> ** \n"
         . "The // ... part is optional.";
    goto SEPARATOR;
}
_consume_line();
like($line, qr|^    \*\* Codename: [^/]+( // [^/]+)? \*\*$|);
goto SEPARATOR;

SECTION:
_consume_line();
if ( (my ($pre, $section, $post)) = ($line =~ /^(\s*)(\S.*\S)(\s*)$/) ) {
    defined $pre or $pre = '';
    defined $post or $post = '';
    my $lpre = length $pre;
    my $lpost = length $post;
    $pre ne '    ' and _fail("line starts with $lpre blank caracters, but it should start with exactly 4 spaces");
    $lpost and _fail("line ends with $lpre blank caracters, but it should not");
    like($section, qr/^\[ ($possible_sections) \]$/, "line $line_nb: check section");
    $current_section = [];
    $current_item_start = undef;
    $current_item = undef;
    push @$current_version, { $section => $current_section };
} else {
    _fail_bail_out("line should contain a section string, but it contains '$line'.");
}
goto WHERE_NEXT;

ITEM_START:
_consume_line();
if ( (my ($pre, $item_start)) = ($line =~ /^(\s*)(.+)$/) ) {
    defined $pre or $pre = '';
    my $lpre = length $pre;
    $pre ne '    ' and _fail("line starts with $lpre blank caracters, but it should start with exactly 4 spaces");
    like($item_start, qr/^\* /, "line $line_nb: item line starts with *");
    $current_item_start = [ $item_start ];
    $current_item = undef;
    push @$current_section, $current_item_start;
} else {
    _fail_bail_out("line should contain an item start, but it contains '$line'.");
}
goto WHERE_NEXT;

ITEM:
_consume_line();
if ( (my ($pre, $item)) = ($line =~ /^(\s*)(.+)$/) ) {
    defined $pre or $pre = '';
    my $lpre = length $pre;
    $pre ne '      ' and _fail("line starts with $lpre blank caracters, but it should start with exactly 6 spaces");
    _pass();
    $current_item = $item;
    push @$current_item_start, $item;
} else {
    _fail_bail_out("line should contain an item, but it contains '$line'.");
}
goto WHERE_NEXT;

END_CHANGES:

} # end scoping


# we are doing advanced testing in a subtest because we couldn't compute the
# number of test upfront. But now we can

subtest 'Advanced testing of changelog' => sub {

    my $sections_count = 0;

    my $versions_next_count = 0;
    my $versions_count = scalar(@struct);
    foreach my $version_struct (@struct) {
        my $version_number = (keys(%$version_struct))[0];
        $version_number eq '{{$NEXT}}'
          and $versions_next_count++;
        $sections_count += scalar(@{$version_struct->{$version_number}});
    }

    my $section_comparison_count = ( ($versions_count-1) + ( ($versions_count-1) - $versions_next_count ) * 2);
    $section_comparison_count >= 0
      or $section_comparison_count = 0;

    plan tests => $section_comparison_count + $sections_count;

    my $previous_version_struct;
    foreach my $version_struct (reverse @struct) {
        my $version_number = (keys(%$version_struct))[0];
        my $previous_version_number = (keys(%$previous_version_struct))[0];
        if (defined $previous_version_number) {
            isnt ($previous_version_number, '{{$NEXT}}', "version $version_number has {{\$NEXT}} as previous version, that's wrong");
            if ($version_number ne '{{$NEXT}}') {
                my ($v1,  $v2,  $v3,  $d1,  $d2,   $d3) = ( $version_number          =~ /^(\d)\.(\d{4})(?:_(\d{2}))?\s+(\d{2})\.(\d{2})\.(\d{4})$/ );
                my ($pv1, $pv2, $pv3, $pd1, $pd2, $pd3) = ( $previous_version_number =~ /^(\d)\.(\d{4})(?:_(\d{2}))?\s+(\d{2})\.(\d{2})\.(\d{4})$/ );
                ok($v1 >= $pv1 || $v2 >= $pv2 || ($v3||0) >= ($pv3||0), "version '$version_number' is not greater than '$previous_version_number', that's wrong");
                ok($d3 >= $pd3 || $d2 >= $pd2 ||      $d1 >= $pd1,      "version '$version_number' is not newer (date) than '$previous_version_number', that's wrong");
            }
        }
        my $previous_section_name;
        foreach my $section_struct (@{$version_struct->{$version_number}}) {
            my $section_name = (keys(%$section_struct))[0];
            if (defined $previous_section_name) {
                my @temp = @possible_sections;
                while (1) {
                    my $s = shift @temp;
                    $previous_section_name eq "[ $s ]"
                      and last;
                }
                my $allowed_section_names = join('|', @temp);
                like($section_name, qr/^\[ ($allowed_section_names) \]$/, "failure : section '$section_name' cannot come after '$previous_section_name'.");
            } else {
                Test::More::pass('first section ok');
            }
            $previous_section_name = $section_name;
        }
        $previous_version_struct = $version_struct;
    }
};
