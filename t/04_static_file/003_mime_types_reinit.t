use strict;
use warnings;

use IO::Handle;

use Dancer::MIME;
use Dancer ':syntax';
use Dancer::ModuleLoader;

use Test::More import => ['!pass'];

plan tests => 3;

# Test that MIME::Types gets initialised before the fork, as it'll
# fail to read from DATA in all bar one child process in a
# mod_perl-type preforking situation.
#
# See the comment near the top of Dancer/MIME.pm, and GH#136. 

my @cts;
for (my $i = 0; $i < 3; $i++) {
        my ($p, $c) = (IO::Handle->new, IO::Handle->new);
        pipe($p, $c);

        if (my $pid = fork()) {
                # parent
                $c->close;
                my $ct = $p->getline;
                $p->close();
                waitpid($pid, 0);
                push @cts, $ct;
        }
        else {
                # child
                $p->close;
                my $mime = Dancer::MIME->instance();
                my $type = $mime->for_name('css');
                $c->print($type);
                $c->close;
                exit 0;
        }
}

ok($cts[0] eq 'text/css');
ok($cts[1] eq 'text/css');
ok($cts[2] eq 'text/css');
