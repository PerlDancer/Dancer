use Test::More;

use strict;
use warnings;

use Dancer::ModuleLoader;

plan skip_all => "the Clone module is needed for this test"
    unless Dancer::ModuleLoader->load('Clone');

plan tests => 25;

use Dancer::Object;

{
    package Person;
    use base 'Dancer::Object';
    __PACKAGE__->attributes('name', 'age', 'sex');
    __PACKAGE__->attribute( lang => 'perl' );
}

my $p = Person->new;
ok $p->init, 'init works';

isa_ok $p, 'Person';
can_ok $p, qw(new init name age sex lang);

ok $p->name('john'), 'setting name';
ok $p->age(10), 'setting age';
ok $p->sex('male'), 'setting sex';

is $p->name, 'john', 'getting name';
is $p->age, 10, 'getting age';
is $p->sex, 'male', 'getting sex';
is $p->lang, 'perl', 'getting lang default';

my $p2 = $p->clone;
isnt $p, $p2, "clone is not the same object";
is $p->age, $p2->age, "clone values are OK";
is $p->lang, $p2->lang, "clone values are still OK";

my $attrs = Person->get_attributes();
is_deeply $attrs, ['name', 'age', 'sex', 'lang'], "attributes are ok";

{
    package Person::Child;
    use base 'Person';
    __PACKAGE__->attributes('parent');
    __PACKAGE__->attribute( toy => 'teddy' );
}

my $child = Person::Child->new();
ok $child->parent($p), 'setting parent';
ok $child->name('bob'), 'setting child name';
ok $child->age(5), 'setting child age';
ok $child->lang('perl6'), 'setting child lang';

is $child->age, 5, 'age is ok';
is $child->parent->sex, 'male', 'age is ok';
is $child->toy, 'teddy', 'toy is ok';
is $child->lang, 'perl6', 'lang is ok';
is $child->parent->lang, 'perl', 'parent\'s lang is ok';
my $child_attrs = Person::Child->get_attributes();
is_deeply $child_attrs, ['parent', 'toy', 'name', 'age', 'sex', 'lang'], "attributes are ok";

{
    package Person::Child::Blond;
    use base 'Person::Child';
    __PACKAGE__->attributes('hair_length');
}

my $blond_child = Person::Child::Blond->new();
my $blond_child_attrs = Person::Child::Blond->get_attributes();
is_deeply $blond_child_attrs, ['hair_length', 'parent', 'toy', 'name', 'age', 'sex', 'lang'], "attributes are ok";
