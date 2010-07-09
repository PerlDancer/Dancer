use Test::More tests => 5, import => ['!pass'];
use strict;
use warnings;

use Dancer::App;

my $app = Dancer::App->new;
isa_ok $app, 'Dancer::App';

is $app->name, 'main', 
    "default app is 'main'";

eval { my $other = Dancer::App->new };
like $@, qr/an app named 'main' already exists/, 
    "cannot create twice the same app";

my $other = Dancer::App->new(name => 'Foo::Bar');
is $other->name, 'Foo::Bar', 
    "Foo::Bar app created";

isa_ok(Dancer::App->current(), 'Dancer::App',
    "Dancer::App->current exists");
is(Dancer::App->current->name, 'main',
    "current is main");
ok(Dancer::App->current(Dancer::App->new(name => "Other")),
    "set current to 'Other'");
is(Dancer::App->current->name, 'Other',
    "current is 'Other'");
