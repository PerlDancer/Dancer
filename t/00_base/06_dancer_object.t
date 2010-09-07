use Test::More;

use strict;
use warnings;

use Dancer::ModuleLoader;

plan skip_all => "the Clone module is needed for this test" 
    unless Dancer::ModuleLoader->load('Clone');

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

done_testing;
