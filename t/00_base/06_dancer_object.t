use Test::More;

use strict;
use warnings;

use Dancer::ModuleLoader;

plan skip_all => "the Clone module is needed for this test"
    unless Dancer::ModuleLoader->load('Clone');

plan tests => 18;

use Dancer::Object;

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

my $p2 = $p->clone;
isnt $p, $p2, "clone is not the same object";
is $p->age, $p2->age, "clone values are OK";

my $attrs = Person->get_attributes();
is_deeply $attrs, ['name', 'age', 'sex'], "attributes are ok";

{
    package Person::Child;
    use base 'Person';
    __PACKAGE__->attributes('parent');
}

my $child = Person::Child->new();
ok $child->parent($p), 'setting parent';
ok $child->name('bob'), 'setting child name';
ok $child->age(5), 'setting child age';

is $child->age, 5, 'age is ok';
is $child->parent->sex, 'male', 'age is ok';
my $child_attrs = Person::Child->get_attributes();
is_deeply $child_attrs, ['parent', 'name', 'age', 'sex'], "attributes are ok";
