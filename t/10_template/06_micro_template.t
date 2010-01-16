use Test::More;


use strict;
use warnings;
use Dancer::ModuleLoader;
use Dancer::FileUtils 'path';

use lib 't/lib';
use EasyMocker;

BEGIN {
    plan skip_all => "need Text::MicroTemplate to run this test"
      unless Dancer::ModuleLoader->load('Text::MicroTemplate::File');
    plan tests => 6;
    use_ok 'Dancer::Template::MicroTemplate';
}

my $mock = {'Text::MicroTemplate::File' => 0};
mock 'Dancer::ModuleLoader' => method 'load' => should sub { $mock->{$_[1]} };

my $engine;
eval { $engine = Dancer::Template::MicroTemplate->new };
like $@, qr/Text::MicroTemplate is needed by Dancer::Template::MicroTemplate/,
  "Text::MicroTemplate dependency caught at init time";

$mock->{'Text::MicroTemplate::File'} = 1;
eval { $engine = Dancer::Template::MicroTemplate->new };
is $@, '',
  "Text::MicroTemplate dependency is not triggered if Text::MicroTemplate is there";

my $template = path('t', '10_template', 'index.mt');
my $result = $engine->render(
    $template,
    {   var1 => 1,
        var2 => 2,
        foo  => 'one',
        bar  => 'two',
        baz  => 'three'
    }
);

my $expected =
  'this is var1="1" and var2=2' . "\n\nanother line\n\n one two three\n";
is $result, $expected, "processed a template given as a file name";

$template = '% my $one=1; one=<%= $one %>';

eval { $engine->render($template, {one => 1, two => 2, three => 3}) };
like $@, qr/is not a regular file/, "prorotype failure detected";

eval { $engine->render(\$template, {one => 1, two => 2, three => 3}) };
like $@, qr/is not a regular file/, "prototype failure detected";
