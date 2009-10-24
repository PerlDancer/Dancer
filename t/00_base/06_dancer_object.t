use Test::More 'no_plan';

use strict;
use warnings;

use_ok 'Dancer::Object';

{
    package Person;
    use base 'Dancer::Object';
    __PACKAGE__->attributes('name', 'age', 'sex');
}

my $p = Person->new;
ok $p->init, 'init works';

isa_ok $p, 'Person';
can_ok $p, qw(new init name age sex);

ok $p->name('john'), 'setting name';
ok $p->age(10), 'setting age';
ok $p->sex('male'), 'setting sex';

is $p->name, 'john', 'getting name';
is $p->age, 10, 'getting age';
is $p->sex, 'male', 'getting sex';
