use Test::More;


use strict;
use warnings;
use Dancer::ModuleLoader;
use Dancer::FileUtils 'path';

use File::Spec;
use lib File::Spec->catdir( 't', 'lib' );
use EasyMocker;

BEGIN {
    plan skip_all => "need Template to run this test" 
        unless Dancer::ModuleLoader->load('Template');
    plan tests => 17;
    use_ok 'Dancer::Template::TemplateToolkit';
};

my $mock = { 'Template' => 0 };
mock 'Dancer::ModuleLoader'
    => method 'load'
    => should sub { $mock->{ $_[1] } };
mock 'Template'
    => method 'can'
    => should sub { 0 };

my $engine;
eval { $engine = Dancer::Template::TemplateToolkit->new };
like $@, qr/Template is needed by Dancer::Template::TemplateToolkit/,
    "Template dependency caught at init time";

$mock->{Template} = 1;
eval { $engine = Dancer::Template::TemplateToolkit->new };
is $@, '',
    "Template dependency is not triggered if Template is there";

# as a file path
my $template = path('t', '10_template', 'index.txt');
my $result = $engine->render(
    $template,
    { var1 => 1,
      var2 => 2,
      foo => 'one',
      bar => 'two',
      baz => 'three'});

$result =~ s/\r//g;

my $expected = 'this is var1="1" and var2=2'."\n\nanother line\n\n one two three\n\n1/1\n";
is $result, $expected, "processed a template given as a file name";

# as a filehandle
my $fh;
open $fh, '<', $template or die "cannot open file $template: $!";
$result = $engine->render(
    $fh, 
    { var1 => 1,
      var2 => 2,
      foo => 'one',
      bar => 'two',
      baz => 'three'});

is $result, $expected, "processed a template given as a file handle";

$expected = "one=1, two=2, three=3";
$template = "one=<% one %>, two=<% two %>, three=<% three %>";

eval { $engine->render($template, { one => 1, two => 2, three => 3}) };
like $@, qr/doesn't exist or not a regular file/, "prorotype failure detected";

$result = $engine->render(\$template, { one => 1, two => 2, three => 3});
is $result, $expected, "processed a template given as a scalar ref";

$engine->set_wrapper(outer => \'<!<% content %>>');
$result = $engine->render(\$template, { one => 1, two => 2, three => 3});
is $result, '<!'.$expected.'>', "processed a template given as a scalar ref with outer wrapper";

$engine->set_wrapper(inner => \'--<% content %>--');
$result = $engine->render(\$template, { one => 1, two => 2, three => 3});
is $result, '<!--'.$expected.'-->', "processed a template given as a scalar ref with outer and inner wrapper";

$engine->set_wrapper(\'-#-<% content %>-#-');
$result = $engine->render(\$template, { one => 1, two => 2, three => 3});
is $result, '-#-'.$expected.'-#-', "processed a template given as a scalar ref with single wrapper";

$engine->reset_wrapper;
$result = $engine->render(\$template, { one => 1, two => 2, three => 3});
is $result, '<!--'.$expected.'-->', "processed a template given as a scalar ref with resetted wrapper";

is ${$engine->unset_wrapper('outer')}, '<!<% content %>>', 'unset outer wrapper';
$result = $engine->render(\$template, { one => 1, two => 2, three => 3});
is $result, '--'.$expected.'--', "processed a template given as a scalar ref with inner wrapper";

is ${$engine->unset_wrapper('inner')}, '--<% content %>--', 'unset inner wrapper';
$result = $engine->render(\$template, { one => 1, two => 2, three => 3});
is $result, $expected, "processed a template given as a scalar ref with no wrapper";

eval { $engine->set_wrapper(nonsense => 'nothing') };
is $@, "core - template - 'nonsense' isn't a valid identifier", 'wrong identifier for set_wrapper';

eval { $engine->unset_wrapper('nonsense') };
is $@, "core - template - 'nonsense' isn't a valid identifier", 'wrong identifier for unset_wrapper';

