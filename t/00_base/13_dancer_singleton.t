use strict;
use warnings;

use Test::More import => ['!pass'];

plan tests => 10;

my $test_counter = 0;

{
    package MySingleton;
    use base qw(Dancer::Object::Singleton);

    __PACKAGE__->attributes( qw/foo/ );

    sub init {
        my ($class, $instance) = @_;
        $test_counter++;
        $instance->foo('bar');
    }
}

eval { MySingleton->new() };
like $@, qr/you can't call 'new'/, 'new unauthorized';

eval { MySingleton->clone() };
like $@, qr/you can't call 'clone'/, 'clone unauthorized';

can_ok 'MySingleton', 'foo';

my $instance = MySingleton->instance();
ok $instance, 'instance build';
is $test_counter, 1, 'counter incremented';
is $instance->foo, 'bar', 'attribute is set';
$instance->foo('baz');
is $instance->foo, 'baz', 'attribute changed';

my $instance2 =  MySingleton->instance();
ok $instance2, 'instance retrieved';
is $instance2, $instance, 'instance is the same';
is $test_counter, 1, 'counter was not incremented';

