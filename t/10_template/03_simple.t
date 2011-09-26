use Test::More tests => 9;

use strict;
use warnings;
use Dancer::FileUtils 'path';

use Dancer::Template::Simple;

{
    package Foo;
    use base 'Dancer::Object';
    Foo->attributes('x', 'y');

    sub method { "yeah" }
}

# variable interpolation, with file-based template

my $engine = Dancer::Template::Simple->new;
my $template = path('t', '10_template', 'index.txt');

my $result = $engine->render(
    $template,
    { var1 => "xxx",
      var2 => "yyy",
      foo => 'one',
      bar => 'two',
      baz => 'three'});

my $expected = 'this is var1="xxx" and var2=yyy'."\n\nanother line\n\n one two three\n\nxxx/xxx\n";
is $result, $expected, "template got processed successfully";

# variable interpolation, with scalar-based template

$expected = "one=1, two=2, three=3 - 77";
$template = "one=<% one %>, two=<% two %>, three=<% three %> - <% hash.key %>";

eval { $engine->render($template, { one => 1, two => 2, three => 3}) };
like $@, qr/is not a regular file/, "prorotype failure detected";

$result = $engine->render(\$template, {
    one => 1, two => 2, three => 3,
    hash => { key => 77 },
});
is $result, $expected, "processed a template given as a scalar ref";

# complex variable interpolation (object, coderef and hash)

my $foo = Foo->new;
$foo->x(42);

$template = 'foo->x == <% foo.x %> foo.method == <% foo.method %> foo.dumb=\'<% foo.dumb %>\'';
$expected = 'foo->x == 42 foo.method == yeah foo.dumb=\'\'';
$result   = $engine->render(\$template, { foo => $foo });
is $result, $expected, 'object are interpolated in templates';

$template = 'code = <% code %>, code <% hash.code %>';
$expected = 'code = 42, code 42';
$result   = $engine->render(\$template, {
                code => sub { 42 },
                hash => { 
                    code => sub { 42 }
                }
            });
is $result, $expected, 'code ref are interpolated in templates';

$template = 'array: <% array %>, hash.array: <% hash.array %>';
$expected = 'array: 1 2 3 4 5, hash.array: 6 7 8';
$result   = $engine->render(\$template, {
                array => [1, 2, 3, 4, 5],
                hash => { array => [6, 7, 8] }});
is $result, $expected, "arrayref are interpolated in templates";

# if-then-else
$template = '<% if want %>hello<% else %>goodbye<% end %> world';
$result   = $engine->render(\$template, {want => 1});
is $result, 'hello world', "true boolean condition matched";
$result   = $engine->render(\$template, {want => 0});
is $result, 'goodbye world', "false boolean condition matched";

$template = 'one: 1
two: <% two %>
three : <% three %>';
$result = $engine->render(\$template, {two => 2, three => 3 });
is $result, 'one: 1
two: 2
three : 3', "multiline template processed";
