use strict;
use warnings;
use Test::More tests => 5;

{

    package test::dancer::deprecated;
    use base 'Dancer::Object';
    use Dancer::Deprecation;

    sub foo {
        Dancer::Deprecation->deprecated(
            feature => 'foo',
            version => '0.1',
            message => 'calling foo is deprecated, you should use bar',
        );
    }

    sub bar {
        Dancer::Deprecation->deprecated(
            'calling bar is also deprecated, you should use baz');
    }

    sub baz {
        Dancer::Deprecation->deprecated();
    }

    sub foo_bar_baz {
        Dancer::Deprecation->deprecated(
            version => '0.1',
            feature => 'foo_bar_baz',
        );
    }

    sub fatal {
        Dancer::Deprecation->deprecated(
            message => 'this should die',
            fatal   => 1,
        );
    }
}

my $warn;
local $SIG{__WARN__} = sub { $warn = $_[0] };

my $t = test::dancer::deprecated->new();
$t->foo();

like $warn, qr/calling foo is deprecated, you should use bar since version 0.1/,
  'deprecation with feature, message and version';

$warn = undef;

$t->bar();
like $warn, qr/test::dancer::deprecated::bar has been deprecated/,
  'deprecation with only message';

$warn = undef;

$t->baz();
like $warn, qr/test::dancer::deprecated::baz has been deprecated/,
  'deprecation with default message';

$warn = undef;

$t->foo_bar_baz();
like $warn, qr/foo_bar_baz has been deprecated since version 0.1/,
  'deprecation with feature and version';

eval {$t->fatal};
like $@, qr/this should die/;

