use 5.006;
use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::Compile 2.054

use Test::More;

plan tests => 71 + ($ENV{AUTHOR_TESTING} ? 1 : 0);

my @module_files = (
    'Dancer.pm',
    'Dancer/App.pm',
    'Dancer/Config.pm',
    'Dancer/Config/Object.pm',
    'Dancer/Continuation.pm',
    'Dancer/Continuation/Halted.pm',
    'Dancer/Continuation/Route.pm',
    'Dancer/Continuation/Route/ErrorSent.pm',
    'Dancer/Continuation/Route/FileSent.pm',
    'Dancer/Continuation/Route/Forwarded.pm',
    'Dancer/Continuation/Route/Passed.pm',
    'Dancer/Continuation/Route/Templated.pm',
    'Dancer/Cookie.pm',
    'Dancer/Cookies.pm',
    'Dancer/Deprecation.pm',
    'Dancer/Engine.pm',
    'Dancer/Error.pm',
    'Dancer/Exception.pm',
    'Dancer/Exception/Base.pm',
    'Dancer/Factory/Hook.pm',
    'Dancer/FileUtils.pm',
    'Dancer/GetOpt.pm',
    'Dancer/HTTP.pm',
    'Dancer/Handler.pm',
    'Dancer/Handler/Debug.pm',
    'Dancer/Handler/PSGI.pm',
    'Dancer/Handler/Standalone.pm',
    'Dancer/Hook.pm',
    'Dancer/Hook/Properties.pm',
    'Dancer/Logger.pm',
    'Dancer/Logger/Abstract.pm',
    'Dancer/Logger/Capture.pm',
    'Dancer/Logger/Capture/Trap.pm',
    'Dancer/Logger/Console.pm',
    'Dancer/Logger/Diag.pm',
    'Dancer/Logger/File.pm',
    'Dancer/Logger/Note.pm',
    'Dancer/Logger/Null.pm',
    'Dancer/MIME.pm',
    'Dancer/ModuleLoader.pm',
    'Dancer/Object.pm',
    'Dancer/Object/Singleton.pm',
    'Dancer/Plugin.pm',
    'Dancer/Plugin/Ajax.pm',
    'Dancer/Renderer.pm',
    'Dancer/Request.pm',
    'Dancer/Request/Upload.pm',
    'Dancer/Response.pm',
    'Dancer/Route.pm',
    'Dancer/Route/Cache.pm',
    'Dancer/Route/Registry.pm',
    'Dancer/Serializer.pm',
    'Dancer/Serializer/Abstract.pm',
    'Dancer/Serializer/Dumper.pm',
    'Dancer/Serializer/JSON.pm',
    'Dancer/Serializer/JSONP.pm',
    'Dancer/Serializer/Mutable.pm',
    'Dancer/Serializer/XML.pm',
    'Dancer/Serializer/YAML.pm',
    'Dancer/Session.pm',
    'Dancer/Session/Abstract.pm',
    'Dancer/Session/Simple.pm',
    'Dancer/Session/YAML.pm',
    'Dancer/SharedData.pm',
    'Dancer/Template.pm',
    'Dancer/Template/Abstract.pm',
    'Dancer/Template/Simple.pm',
    'Dancer/Template/TemplateToolkit.pm',
    'Dancer/Test.pm',
    'Dancer/Timer.pm'
);

my @scripts = (
    'bin/dancer'
);

# no fake home requested

my $inc_switch = -d 'blib' ? '-Mblib' : '-Ilib';

use File::Spec;
use IPC::Open3;
use IO::Handle;

open my $stdin, '<', File::Spec->devnull or die "can't open devnull: $!";

my @warnings;
for my $lib (@module_files)
{
    # see L<perlfaq8/How can I capture STDERR from an external command?>
    my $stderr = IO::Handle->new;

    my $pid = open3($stdin, '>&STDERR', $stderr, $^X, $inc_switch, '-e', "require q[$lib]");
    binmode $stderr, ':crlf' if $^O eq 'MSWin32';
    my @_warnings = <$stderr>;
    waitpid($pid, 0);
    is($?, 0, "$lib loaded ok");

    shift @_warnings if @_warnings and $_warnings[0] =~ /^Using .*\bblib/
        and not eval { require blib; blib->VERSION('1.01') };

    if (@_warnings)
    {
        warn @_warnings;
        push @warnings, @_warnings;
    }
}

foreach my $file (@scripts)
{ SKIP: {
    open my $fh, '<', $file or warn("Unable to open $file: $!"), next;
    my $line = <$fh>;

    close $fh and skip("$file isn't perl", 1) unless $line =~ /^#!\s*(?:\S*perl\S*)((?:\s+-\w*)*)(?:\s*#.*)?$/;
    my @flags = $1 ? split(' ', $1) : ();

    my $stderr = IO::Handle->new;

    my $pid = open3($stdin, '>&STDERR', $stderr, $^X, $inc_switch, @flags, '-c', $file);
    binmode $stderr, ':crlf' if $^O eq 'MSWin32';
    my @_warnings = <$stderr>;
    waitpid($pid, 0);
    is($?, 0, "$file compiled ok");

    shift @_warnings if @_warnings and $_warnings[0] =~ /^Using .*\bblib/
        and not eval { require blib; blib->VERSION('1.01') };

    # in older perls, -c output is simply the file portion of the path being tested
    if (@_warnings = grep { !/\bsyntax OK$/ }
        grep { chomp; $_ ne (File::Spec->splitpath($file))[2] } @_warnings)
    {
        warn @_warnings;
        push @warnings, @_warnings;
    }
} }



is(scalar(@warnings), 0, 'no warnings found')
    or diag 'got warnings: ', ( Test::More->can('explain') ? Test::More::explain(\@warnings) : join("\n", '', @warnings) ) if $ENV{AUTHOR_TESTING};


