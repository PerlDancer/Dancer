use strict;
use warnings;

use Test::More import => ['!pass'];
use Dancer ':syntax';
use Dancer::Session::Abstract;
use Dancer::Session::YAML;
use Dancer::ModuleLoader;
use Dancer::FileUtils qw(path);
use File::Spec;

my $class = 'Dancer::Session::Abstract';

subtest 'build_id format' => sub {
    my $id = $class->build_id;

    ok(defined($id), 'build_id returns a defined value');
    is(length($id), 32, 'build_id returns a 32-character string');
    like($id, qr/\A[A-Za-z0-9_\-~]+\z/,
         'build_id returns a URL-safe base64 string');
};

subtest 'validate_session_id hardened behaviour' => sub {
    my $id = $class->build_id;

    ok($class->validate_session_id($id),
       'generated ID validates');
    ok(!$class->validate_session_id("$id\n"),
       'trailing newline rejected');
    ok(!$class->validate_session_id("a\nb"),
       'embedded newline rejected');
    ok($class->validate_session_id('a' x 4096),
       'maximum-length ID validates');
    ok(!$class->validate_session_id('x' x 4097),
       'overly long ID rejected');
    ok(!$class->validate_session_id(undef),
       'undef rejected');

    # existing format (old digit-only IDs) should still validate
    ok($class->validate_session_id('123456789012345678901234567890'),
       'old digit-only IDs still validate');
};

subtest 'build_id uniqueness' => sub {
    my %seen;
    my $dups = 0;
    for (1 .. 1000) {
        my $i = $class->build_id;
        $seen{$i} ? $dups++ : ($seen{$i} = 1);
    }
    is($dups, 0, 'no duplicate IDs in 1000 generated IDs');
};

subtest 'yaml_file accepts base64url IDs' => sub {
    plan skip_all => 'YAML required'
        unless Dancer::ModuleLoader->load('YAML');

    # Fake up a session_dir so yaml_file can call path(setting(...))
    my $id = $class->build_id;
    set appdir  => File::Spec->tmpdir;
    set session_dir => path(File::Spec->tmpdir, 'sessions');

    my $yaml_file = Dancer::Session::YAML::yaml_file($id);
    ok(defined($yaml_file), 'yaml_file returns a value');
    like($yaml_file, qr/\Q$id\E\.yml\z/,
         'yaml_file produces correct filename for base64url ID');

    # IDs with disallowed characters must not produce a filename
    is(Dancer::Session::YAML::yaml_file('../etc/passwd'),
       undef, 'path traversal in ID is rejected');
};

done_testing;
