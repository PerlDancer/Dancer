# this test makes sure the "console" logger send log messages to STDERR

use strict;
use warnings;
use Test::More import => ['!pass'];

plan skip_all => "Test::Output is needed for this test"
    unless Dancer::ModuleLoader->load('Test::Output');

plan tests => 4;

use Dancer ':syntax';
set logger => 'Console';

Test::Output::stderr_like(
    sub { Dancer::Logger::warning(['a']) }, 
    qr/\[\d+\]  warn @.+> \['a'\] in/,
    'Arrayref correctly serialized',
);

Test::Output::stderr_like(
    sub { Dancer::Logger::warning( { this => 'that' } ) }, 
    qr/\[\d+\]  warn @.+> \{'this' => 'that'\} in/,
    'Hashref correctly serialized',
);

Test::Output::stderr_like(
    sub { Dancer::Logger::warning( qw/hello world/ ) }, 
    qr/\[\d+\]  warn @.+> helloworld in/,
    'Multiple arguments are okay',
);

Test::Output::stderr_like(
    sub { Dancer::Logger::warning( { b => 1, a => 2, e => 3, d => 4, c => 5}) }, 
    qr/\[\d+\]  warn @.+> \{'a' => 2,'b' => 1,'c' => 5,'d' => 4,'e' => 3\}/,
    'Hash keys are sorted okay',
);
