# this test makes sure the "console" logger send log messages to STDERR

use strict;
use warnings;
use Test::More import => ['!pass'];

plan skip_all => "Test::Output is needed for this test"
    unless Dancer::ModuleLoader->load('Test::Output');

plan tests => 3;

use Dancer ':syntax';
set logger => 'Console';

Test::Output::stderr_like(
    sub { Dancer::Logger::warning(['a']) }, 
    qr/\[\d+\]  warn @.+> \['a'\] in/,
    'Arrayref correctly serialized',
);

Test::Output::stderr_like(
    sub { Dancer::Logger::warning( { this => 'that' } ) }, 
    qr/\[\d+\]  warn @.+> {'this' => 'that'} in/,
    'Hashref correctly serialized',
);

Test::Output::stderr_like(
    sub { Dancer::Logger::warning( qw/hello world/ ) }, 
    qr/\[\d+\]  warn @.+> helloworld in/,
    'Multiple arguments are okay',
);

