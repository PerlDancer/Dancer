use strict;
use warnings;

use Test::More import => ['!pass'];

use Dancer ':syntax';
use Dancer::Template::TemplateToolkit;

eval "use Template; 1" 
    or plan skip_all => "tests require module 'Template' to be installed";

plan tests => 18;

# scoping for $Carp::Verbose localization

{
    # first of all, test without verbose Exceptions
    local $Dancer::Exception::Verbose = 0;
    eval { Dancer::Template::TemplateToolkit->new->render('/not/a/valid/file'); };
    my @error_lines = split(/\n/, $@);
    is(scalar(@error_lines), 1, "test non verbose croak");
    like($error_lines[0], qr!^core - template - '/not/a/valid/file' doesn\'t exist or not a regular file at!, "test non verbose croak");
}

{
    # same with verbose Exceptions
    local $Dancer::Exception::Verbose = 1;
    eval { Dancer::Template::TemplateToolkit->new->render('/not/a/valid/file'); };
    my @error_lines = split(/\n/, $@);
    is(scalar(@error_lines), 3, "test verbose croak");
    like($error_lines[0], qr!^core - template - '/not/a/valid/file' doesn\'t exist or not a regular file at!, "test verbose croak");
    like $error_lines[1] 
        => qr!^\s*Dancer::Template::TemplateToolkit::render\(['"]?Dancer::Template::TemplateToolkit=HASH\(0x[0-9a-fA-F]+\)['"]?, ['"]/not/a/valid/file['"]\) called at!, 
        "test verbose croak stack trace";
    like($error_lines[2], qr!^\s*eval \{...\} called at (?:[.]/)?\Q$0\E!, "test verbose croak stack trace");
}

{
    # test that default Dancer traces setting is no verbose
    is(setting('traces'), 0, "default 'traces' option set to 0");
    is($Carp::Verbose, 0, "default Carp verbose is 0");
    is($Dancer::Exception::Verbose, 0, "default Dancer Exception verbose is 0");
    eval { Dancer::Template::TemplateToolkit->new->render('/not/a/valid/file'); };
    my @error_lines = split(/\n/, $@);
    is(scalar(@error_lines), 1, "test non verbose croak 2");
    like($error_lines[0], qr!^core - template - '/not/a/valid/file' doesn\'t exist or not a regular file at!, "test non verbose croak 2");
}

{
    # test setting traces to 1
    ok(setting(traces => 1), 'can set traces');
    is($Carp::Verbose, 0, "new Carp verbose is 1");
    is($Dancer::Exception::Verbose, 1, "default Dancer Exception verbose is 1");
    eval { Dancer::Template::TemplateToolkit->new->render('/not/a/valid/file'); };
    my @error_lines = split(/\n/, $@);
    is(scalar(@error_lines), 3, "test verbose croak");
    like($error_lines[0], qr!^core - template - '/not/a/valid/file' doesn\'t exist or not a regular file at!, "test verbose croak");
    like $error_lines[1] 
        => qr!^\s*Dancer::Template::TemplateToolkit::render\(['"]?Dancer::Template::TemplateToolkit=HASH\(0x[0-9a-fA-F]+\)['"]?, ['"]/not/a/valid/file['"]\) called at!, 
        "test verbose croak stack trace";
    like($error_lines[2], qr!^\s*eval \{...\} called at (?:[.]/)?\Q$0\E!, "test verbose croak stack trace");
}
