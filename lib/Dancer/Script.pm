package Dancer::Script;

use strict;
use warnings;
use base 'Dancer::Object';
use FindBin '$RealBin';
use Dancer ':syntax';
use Dancer::ModuleLoader;
use Dancer::Template::Simple;
use Dancer::Renderer;
use File::Basename 'basename';
use File::Path 'mkpath';
use File::Spec::Functions qw/catdir catfile/;
use Getopt::Long;
use Pod::Usage;
use LWP::UserAgent;
use constant FILE => 1;
set logger        => 'console';
set logger_format => '%L> %m';

Dancer::Script->attributes(
    qw(appname root_path check_version dancer_app_dir dancer_script
      dancer_version do_check_dancer_version do_overwrite_all lib_file lib_path)
);

#  Here goes the code to use File::ShareDir 
#  methods. Or at least mimic them without
#  adding the dependency. 
#


# subs
sub init {
    my $class = shift;
    my $self = bless {}, $class;

    if (@_) {

        my %args = @_;
        $self->appname($args{appname});
        $self->root_path($args{path});
        $self->check_version($args{check_version});

    }
    else {
        my ($appname, $path, $check_version) = $self->_parse_opts;
        $self->appname($appname);
        $self->root_path($path);
        $self->check_version($check_version);
    }

    $self->do_overwrite_all(0);
    $self->_validate_app_name;

   #my $AUTO_RELOAD = eval "require Module::Refresh and require Clone" ? 1 : 0;
    $self->dancer_version($Dancer::VERSION);
    $self->_set_application_path;
    $self->_set_script_path;
    $self->_set_lib_path;
    return $self;
}

# options
sub _parse_opts {
    my $self                    = shift;
    my $help                    = 0;
    my $do_check_dancer_version = 1;
    my $name                    = undef;
    my $path                    = '.';


    GetOptions(
        "h|help"          => \$help,
        "a|application=s" => \$name,
        "p|path=s"        => \$path,
        "x|no-check"      => sub { $do_check_dancer_version = 0 },
        "v|version"       => \&version,
    ) or pod2usage(-verbose => 1);

# TODO no need to capitalize it there: store this var inside $self->{perl_interpreter}
# or something similar. Even better, use a Dancer::Object attribute
    my $perl_interpreter = -r '/usr/bin/env' ? '#!/usr/bin/env perl' : "#!$^X";

    pod2usage(-verbose => 1) if $help;
    pod2usage(-verbose => 1) if not defined $name;
    pod2usage(-verbose => 1) unless -d $path && -w $path;
    sub version { print 'Dancer ' . $Dancer::VERSION . "\n"; exit 0; }

    unless (Dancer::ModuleLoader->load('YAML')) {
        print <<NOYAML;
*****
WARNING: YAML.pm is not installed.  This is not a full dependency, but is highly
recommended; in particular, the scaffolded Dancer app being created will not be
able to read settings from the config file without YAML.pm being installed.

To resolve this, simply install YAML from CPAN, for instance using one of the
following commands:

  cpan YAML
  perl -MCPAN -e 'install YAML'
  curl -L http://cpanmin.us | perl - --sudo YAML
*****
NOYAML
    }

    return ($name, $path, $do_check_dancer_version);
}

sub run {
    my $self = shift;
    $self->_version_check if $self->do_check_dancer_version;
    $self->_safe_mkdir($self->dancer_app_dir);

    # TODO private method for _create_node
    $self->create_node($self->_app_tree, $self->dancer_app_dir);
}

sub run_scaffold {
    my $class  = shift;
    my $type   = shift;
    my $method = "_run_scaffold_$type";
    if   ($class->can($method)) { $class->$method; }
    else                        { die "Wrong type of script: $type"; }
}

# must change run_scaffold_* for something
# more intuitive
sub _run_scaffold_cgi {
    my $self = shift;

    require Plack::Runner;

# For some reason Apache SetEnv directives dont propagate
# correctly to the dispatchers, so forcing PSGI and env here
# is safer.
    set apphandler  => 'PSGI';
    set environment => 'production';

    my $psgi = path($RealBin, '..', 'bin', 'app.pl');
    die "Unable to read startup script: $psgi" unless -r $psgi;

    Plack::Runner->run($psgi);
}

sub _run_scaffold_fcgi {
    my $self = shift;

    require Plack::Handler::FCGI;

# For some reason Apache SetEnv directives dont propagate
# correctly to the dispatchers, so forcing PSGI and env here
# is safer.
    set apphandler  => 'PSGI';
    set environment => 'production';

    my $psgi = path($RealBin, '..', 'bin', 'app.pl');
    my $app = do($psgi);
    die "Unable to read startup script: $@" if $@;
    my $server = Plack::Handler::FCGI->new(nproc => 5, detach => 1);

    $server->run($app);
}

sub _validate_app_name {
    my $self = shift;
    if (   $self->appname =~ /[^\w:]/
        || $self->appname =~ /^\d/
        || $self->appname =~ /\b:\b|:{3,}/)
    {

        # TODO use error() instead of STDERR
        error("Error: Invalid application name.\n");
        error(  "Application names must not contain colons,"
              . " dots, hyphens or start with a number.\n");
        exit;
    }
}

sub _set_application_path {
    my $self = shift;
    $self->dancer_app_dir(catdir($self->root_path, $self->_dash_name));
}

sub _set_lib_path {
    my $self = shift;
    unless ($self->appname =~ /::/) {

        $self->lib_file($self->appname);
        $self->lib_path("");
    }
    my @lib_path = split('::', $self->appname);
    my ($lib_file, $lib_path) = (pop @lib_path) . ".pm";
    $lib_path = join('/', @lib_path);
    $self->lib_file($lib_file);
    $self->lib_path($lib_path);
}

sub _set_script_path {
    my $self = shift;
    $self->dancer_script($self->_dash_name);
}

sub _dash_name {
    my $self = shift;
    my $name = $self->appname;
    $name =~ s/\:\:/-/g;
    return $name;
}

sub create_node {
    my $self = shift;
    my $node = shift;
    my $root = shift;
    $root ||= '.';

    my $manifest_name = catfile($root => 'MANIFEST');
    open my $manifest, ">", $manifest_name or die $!;

    # create a closure, so we do not need to get $root passed as
    # argument on _create_node
    my $add_to_manifest = sub {
        my $file       = shift;
        my $root_regex = quotemeta($root);
        $file =~ s{^$root_regex/?}{};
        print $manifest "$file\n";
    };

    $add_to_manifest->($manifest_name);
    $self->_create_node($add_to_manifest, $node, $root);
    close $manifest;
}

sub _create_node {
    my $self            = shift;
    my $add_to_manifest = shift;
    my $node            = shift;
    my $root            = shift;

    my $templates = $self->_templates;

    while (my ($path, $content) = each %$node) {
        $path = catfile($root, $path);

        if (ref($content) eq 'HASH') {
            $self->_safe_mkdir($path);
            $self->_create_node($add_to_manifest, $content, $path);
        }
        elsif (ref($content) eq 'CODE') {

            # The content is a coderef, which, given the path to the file it
            # should create, will do the appropriate thing:
            $content->($path);
            $add_to_manifest->($path);
        }
        else {
            my $file     = basename($path);
            my $dir      = dirname($path);
            my $ex       = ($file =~ s/^\+//); # look for '+' flag (executable)
            my $template = $templates->{$file};

            $path =
              catfile($dir, $file);    # rebuild the path without the '+' flag
            $self->_write_file($path, $template,
                {appdir => File::Spec->rel2abs($root)});
            chmod 0755, $path if $ex;
            $add_to_manifest->($path);
        }
    }
}

sub _app_tree {
    my $self = shift;

    return {
        "Makefile.PL"   => FILE,
        "MANIFEST.SKIP" => FILE,
        lib             => {$self->lib_path => {$self->lib_file => FILE,}},
        "bin"          => {"+app.pl" => FILE,},
        "config.yml"   => FILE,
        "views" => {
            "layouts"  => {"main.tt" => FILE,},
            "index.tt" => FILE,
        },
        "public" => {
            "404.html"       => FILE,
            "500.html"       => FILE,
        },
        "t" => {
            "001_base.t"        => FILE,
            "002_index_route.t" => FILE,
        },
    };
}

sub _safe_mkdir {
    my $self = shift;
    my $dir  = shift;
    if (not -d $dir) {
        debug("Writing directory: $dir\n");
        mkpath $dir or die "could not write the directory $dir: $!";
        debug("Successfully wrote the directory: $dir\n");
    }
    else {
        debug("Not Writing directory: $dir\n");
    }
}

sub _write_file {
    my $self     = shift;
    my $path     = shift;
    my $template = shift;
    my $vars     = shift;
    die "no template found for $path" unless defined $template;

    $vars->{dancer_version} = $self->dancer_version;

    # if file already exists, ask for confirmation
    if (-f $path && (not $self->do_overwrite_all)) {
        print "! $path exists, overwrite? [N/y/a]: ";
        my $res = <STDIN>;
        chomp($res);
        $self->do_overwrite_all = 1 if $res eq 'a';
        return 0 unless ($res eq 'y') or ($res eq 'a');
    }

    my $fh;
    my $content = $self->_process_template($template, $vars);
    debug("Writing file: $path\n");
    open $fh, '>', $path or die "unable to open file `$path' for writing: $!";
    print $fh $content;
    debug("Successfully wrote: $path\n");
    close $fh;
}

sub _process_template {
    my $self     = shift;
    my $template = shift;
    my $tokens   = shift;
    my $engine   = Dancer::Template::Simple->new;
    $engine->{start_tag} = '[%';
    $engine->{stop_tag}  = '%]';
    return $engine->render(\$template, $tokens);
}

sub _write_data_to_file {
    my $self = shift;
    my $data = shift;
    my $path = shift;
    debug("Writing file: $path\n");
    open(my $fh, '>', $path)
      or warn "Failed to write file to $path - $!" and return;
    binmode($fh);
    print {$fh} unpack 'u*', $data;
    debug("Successfully wrote: $path\n");
    close $fh;
    return 1;
}

sub _send_http_request {
    my $self = shift;
    my $url  = shift;
    my $ua   = LWP::UserAgent->new;
    $ua->timeout(5);
    $ua->env_proxy();

    my $response = $ua->get($url);

    if ($response->is_success) {
        return $response->content;
    }
    else {
        return;
    }
}

sub _version_check {
    my $self           = shift;
    my $latest_version = 0;

    my $resp =
      $self->_send_http_request('http://search.cpan.org/api/module/Dancer');

    if ($resp) {
        if ($resp =~ /"version" (?:\s+)? \: (?:\s+)? "(\d\.\d+)"/x) {
            $latest_version = $1;
        }
        else {
            die "Can't understand search.cpan.org's reply.\n";
        }
    }

    return if $self->dancer_version =~ m/_/;

    if ($latest_version > $self->dancer_version) {
        print qq|
The latest stable Dancer release is $latest_version, you are currently using $self->dancer_version.
Please check http://search.cpan.org/dist/Dancer/ for updates.

|;
    }
}

sub _download_file {
    my $self = shift;
    my $path = shift;
    my $url  = shift;
    my $resp = $self->_send_http_request($url);
    if ($resp) {
        open my $fh, '>', $path or die "cannot open $path for writing: $!";
        print $fh $resp;
        close $fh;
    }
    return 1;
}

sub _templates {
    my $self       = shift;
    my $appname    = $self->appname;
    my $appfile    = $self->lib_file;
    my $lib_path   = $self->lib_path;
    my $cleanfiles = $self->appname;
    unless ($lib_path eq "") { $lib_path .= "/"; }

    $appfile    =~ s{::}{/}g;
    $cleanfiles =~ s{::}{-}g;

    return {

        'Makefile.PL' => "use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => '$appname',
    AUTHOR              => q{YOUR NAME <youremail\@example.com>},
    VERSION_FROM        => 'lib/$lib_path$appfile',
    ABSTRACT            => 'YOUR APPLICATION ABSTRACT',
    (\$ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'YAML'       => 0,
        'Dancer'     => [% dancer_version %],
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => '$cleanfiles-*' },
);
",
        'index.tt' => '  
<!-- 
    Credit goes to the Ruby on Rails team for this page 
    has been heavily based on the default Rails page that is 
    built with a scaffolded application.

    Thanks a lot to them for their work.

    See Ruby on Rails if you want a kickass framework in Ruby:
    http://www.rubyonrails.org/
-->

<div id="page">
      <div id="sidebar">
        <ul id="sidebar-items">
          <li>
            <h3>Join the community</h3>
            <ul class="links">

              <li><a href="http://perldancer.org/">PerlDancer</a></li>
              <li><a href="http://twitter.com/PerlDancer/">Official Twitter</a></li>
              <li><a href="http://github.com/sukria/Dancer/">GitHub Community</a></li>
            </ul>
          </li>
          
          <li>
            <h3>Browse the documentation</h3>

            <ul class="links">
              <li><a
              href="http://search.cpan.org/dist/Dancer/lib/Dancer/Introduction.pod">Introduction</a></li>
              <li><a href="http://search.cpan.org/dist/Dancer/lib/Dancer/Cookbook.pod">Cookbook</a></li>
              <li><a href="http://search.cpan.org/dist/Dancer/lib/Dancer/Deployment.pod">Deployment Guide</a></li>
              <li><a
              href="http://search.cpan.org/dist/Dancer/lib/Dancer/Tutorial.pod"
              title="a tutorial to build a small blog engine with Dancer">Tutorial</a></li>
            </ul>
          </li>

          <li>
            <h3>Your application\'s environment</h3>

            <ul>
                <li>Location: <code>[% appdir %]</code></li>
                <li>Template engine: <code><% settings.template %></code></li>
                <li>Logger: <code><% settings.logger %></code></li>
                <li>Environment: <code><% settings.environment %></code></li>
            </ul>

          </li>
        </ul>

      </div>

      <div id="content">
        <div id="header">
          <h1>Perl is dancing</h1>
          <h2>You&rsquo;ve joined the dance floor!</h2>
        </div>

        <div id="getting-started">
          <h1>Getting started</h1>
          <h2>Here&rsquo;s how to get dancing:</h2>
                    
          <h3><a href="#" id="about_env_link">About your application\'s environment</a></h3>

          <div id="about-content" style="display: none;">
            <table>
                <tbody>
                <tr>
                    <td>Perl version</td>
                    <td><tt><% perl_version %></tt></td>
                </tr>
                <tr>
                    <td>Dancer version</td>
                    <td><tt><% dancer_version %></tt></td>
                </tr>
                <tr>
                    <td>Backend</td>
                    <td><tt><% settings.apphandler %></tt></td>
                </tr>
                <tr>
                    <td>Appdir</td>
                    <td><tt>[% appdir %]</tt></td>
                </tr>
                <tr>
                    <td>Template engine</td>
                    <td><tt><% settings.template %></tt></td>
                </tr>
                <tr>
                    <td>Logger engine</td>
                    <td><tt><% settings.logger %></tt></td>
                </tr>
                <tr>
                    <td>Running environment</td>
                    <td><tt><% settings.environment %></tt></td>
                </tr>
                </tbody>
            </table>
          </div>

    <script type="text/javascript">
    $(\'#about_env_link\').click(function() {
        $(\'#about-content\').slideToggle(\'fast\', function() {
            // ok
        });
    });
    </script>


          <ol>          
            <li>
              <h2>Tune your application</h2>

              <p>
              Your application is configured via a global configuration file,
              <tt>config.yml</tt> and an "environment" configuration file,
              <tt>environments/development.yml</tt>. Edit those files if you
              want to change the settings of your application.
              </p>
            </li>

            <li>
              <h2>Add your own routes</h2>

              <p>
              The default route that displays this page can be removed,
              it\'s just here to help you get started. The template used to
              generate this content is located in 
              <code>views/index.tt</code>.
              You can add some routes to <tt>lib/'
          . $lib_path
          . $self->lib_file
          . '</tt>. 
              </p>
            </li>

            <li>
                <h2>Enjoy web development again</h2>

                <p>
                Once you\'ve made your changes, restart your standalone server
                (bin/app.pl) and you\'re ready to test your web application.
                </p>
            </li>

          </ol>
        </div>
      </div>
    </div>
',

        'main.tt' =>
          '<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN"
        "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
<meta http-equiv="Content-type" content="text/html; charset=<% settings.charset %>" />
<title>' . $appname . '</title>
<link rel="stylesheet" href="<% request.uri_base %>/css/style.css" />

<!-- Grab Google CDN\'s jQuery. fall back to local if necessary -->
<script src="http://ajax.googleapis.com/ajax/libs/jquery/1.4.2/jquery.min.js" type="text/javascript"></script>
<script type="text/javascript">/* <![CDATA[ */
    !window.jQuery && document.write(\'<script type="text/javascript" src="<% request.uri_base %>/javascripts/jquery.js"><\/script>\')
/* ]]> */</script>

</head>
<body>
<% content %>
<div id="footer">
Powered by <a href="http://perldancer.org/">Dancer</a> <% dancer_version %>
</div>
</body>
</html>
',

        "app.pl" =>

          "#!/usr/bin/env perl 
use Dancer;
use $appname;
dance;
",

        $self->lib_file =>

          "package $appname;
use Dancer ':syntax';

our \$VERSION = '0.1';

get '/' => sub {
    template 'index';
};

true;
",

# style.css

# error.css
        "404.html" => Dancer::Renderer->html_page(
            "Error 404",
            '<h2>Page Not Found</h2><p>Sorry, this is the void.</p>', 'error'
        ),

        "500.html" => Dancer::Renderer->html_page(
            "Error 500",
            '<h2>Internal Server Error</h2>'
              . '<p>Wooops, something went wrong</p>',
            'error'
        ),

        'config.yml' =>

          "# This is the main configuration file of your Dancer app
# env-related settings should go to environments/\$env.yml
# all the settings in this file will be loaded at Dancer's startup.

# Your application's name
appname: \"$appname\"

# The default layout to use for your application (located in
# views/layouts/main.tt)
layout: \"main\"

# when the charset is set to UTF-8 Dancer will handle for you
# all the magic of encoding and decoding. You should not care
# about unicode within your app when this setting is set (recommended).
charset: \"UTF-8\"

# template engine
# simple: default and very basic template engine
# template_toolkit: TT

template: \"simple\"

# template: \"template_toolkit\"
# engines:
#   template_toolkit:
#     encoding:  'utf8'
#     start_tag: '[%'
#     end_tag:   '%]'

",

        "001_base.t" => "use Test::More tests => 1;
use strict;
use warnings;

use_ok '$appname';
",

        "002_index_route.t" => "use Test::More tests => 2;
use strict;
use warnings;

# the order is important
use $appname;
use Dancer::Test;

route_exists [GET => '/'], 'a route handler is defined for /';
response_status_is ['GET' => '/'], 200, 'response status is 200 for /';
",

    };
}

1;

__END__
=pod

=head1 NAME

Dancer::Script - Object script to create new Dancer applications

=head1 SYNOPSIS

    package My::Dancer::Application;

    use strict;
    use warnings;
    use Dancer::Script;

    #Create a new Dancer application.
	Dancer::Script->init(%params)->run;

    #Deploy in FastCGI.
	Dancer::Script->run_scaffold("fcgi");
	

=head1 DESCRIPTION

Object with methods to quickly and easily create
the framework for a new Dancer application.

This object assists the L<dancer> script which
accepts parameters from the temrinal. For more
information see L<dancer>.

=head1 METHODS

=head2 init

Creates a new object of Dancer::Object.

It accepts arguments in a hash and won't run
until the C<run> method (described
below) is called.

=head2 run

Exists but does not accept any arguments. This method constructs and scaffolds any given application by the params in C<init>.

=head2 run_scaffold

Runs the object for the deployment of a Dancer application.

It accepts a string defining which deployment method to use.
For now, the strings/keywords accepted are C<cgi> for B<CGI> and C<fcgi> for B<FastCGI>. 

=head1 AUTHOR

This module has been written by Carlos Ivan Sosa <gnusosa@gnusosa.net> based on
the script L<dancer> written by Sebastien Deseille
<sebastien.deseille@gmail.com> and Alexis Sukrieh <sukria@cpan.org>.  

=head1 SOURCE CODE

See L<Dancer> for more information.

=head1 LICENSE

This module is free software and is published under the same
terms as Perl itself.

=cut
