use strict;
use warnings;
use Test::More;

BEGIN {
    # Freeze time at Tue, 15-Jun-2010 00:00:00 GMT
    *CORE::GLOBAL::time = sub { return 1276560000 }
}

use Dancer::Cookie;

my $min  = 60;
my $hour = 60 * $min;
my $day  = 24 * $hour;
my $week = 7 * $day;
my $mon  = 30 * $day;
my $year = 365 * $day;

note "expiration times"; {
    my %times = (
        "+2h"                       => "Tue, 15-Jun-2010 02:00:00 GMT",
        "-2h"                       => "Mon, 14-Jun-2010 22:00:00 GMT",
        "1 hour"                    => "Tue, 15-Jun-2010 01:00:00 GMT",
        "3 weeks 4 days 2 hours 99 min 0 secs" => "Sat, 10-Jul-2010 03:39:00 GMT",
        "2 months"                  => "Sat, 14-Aug-2010 00:00:00 GMT",
        "12 years"                  => "Sun, 12-Jun-2022 00:00:00 GMT",

        1288817656 => "Wed, 03-Nov-2010 20:54:16 GMT",
        1288731256 => "Tue, 02-Nov-2010 20:54:16 GMT",
        1288644856 => "Mon, 01-Nov-2010 20:54:16 GMT",
        1288558456 => "Sun, 31-Oct-2010 20:54:16 GMT",
        1288472056 => "Sat, 30-Oct-2010 20:54:16 GMT",
        1288385656 => "Fri, 29-Oct-2010 20:54:16 GMT",
        1288299256 => "Thu, 28-Oct-2010 20:54:16 GMT",
        1288212856 => "Wed, 27-Oct-2010 20:54:16 GMT",

        # Anything not understood is passed through
        "basset hounds got long ears" => "basset hounds got long ears",
    );

    for my $exp (keys %times) {
        my $want = $times{$exp};
        note $want;

        my $cookie = Dancer::Cookie->new(
            name        => "shut.up.and.dance",
            value       => "FMV",
            expires     => $exp
        );

        is($cookie->to_header, 
           "shut.up.and.dance=FMV; path=/; expires=$want; HttpOnly",
           "header with expires");

        is $cookie->expires, $want, "expires";
    }
}

done_testing;
