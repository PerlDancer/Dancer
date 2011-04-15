use Test::More tests => 9, import => ['!pass'];

use strict;
use warnings;

use Dancer;
use Dancer::Template;

my $config = {
    engines => {
        simple => {
            start_tag => '[%',
            stop_tag  => '%]',
        },
    },
};

my $e;

##
eval { $e = Dancer::Template->init() };
is $@, '', 'init a template without agrs';
is $e->name, 'simple', 'name is read';
is_deeply $e->config, {}, 'default settings are set';

##
$e = Dancer::Template->init('simple', $config);
is $e->name, 'simple', 'name is read';
is $e->config->{start_tag}, '[%', 'start_tag is read';
is $e->config->{stop_tag}, '%]', 'stop_tag is read';

##
set 'engines/simple/start_tag' => '[%%';
set 'engines/simple/stop_tag'  => '%%]';

is engine('template')->name, 'simple', 'name is read';
is engine('template')->config->{start_tag}, '[%%', 'start_tag is read';
is engine('template')->config->{stop_tag},  '%%]', 'stop_tag is read';
