package Dancer::Script;

use strict;
use warnings;
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
set logger => 'console';

# subs
sub new { 
	my $class = shift; 
	my $self = bless {}, $class; 

	if (@_){

		my %args = @_;
		$self->{appname} = $args{appname};
		$self->{path} = $args{path};
		$self->{check_version} = $args{check_version};

	}else{
		my ($appname,$path,$check_version) = $self->_parse_opts;
		$self->{appname} = $appname;
		$self->{path} = $path;
		$self->{check_version} = $check_version;
	}
	
	$self->{do_overwrite_all} = 0;
	$self->_validate_app_name;
	#my $AUTO_RELOAD = eval "require Module::Refresh and require Clone" ? 1 : 0;
	$self->{dancer_version} = $Dancer::VERSION;
	$self->_set_application_path;
	$self->_set_script_path;
	$self->_set_lib_path;
	return $self;
}

# options
sub _parse_opts { 
	my $self = shift;
	my $help = 0;
	my $do_check_dancer_version = 1;
	my $name = undef;
	my $path = '.';


	GetOptions(
	    "h|help"          => \$help,
	    "a|application=s" => \$name,
	    "p|path=s"        => \$path,
	    "x|no-check"      => sub { $do_check_dancer_version = 0 },
	    "v|version"       => \&version,
	) or pod2usage( -verbose => 1 );

	my $PERL_INTERPRETER = -r '/usr/bin/env' ? '#!/usr/bin/env perl' : "#!$^X";

	pod2usage( -verbose => 1 ) if $help;
	pod2usage( -verbose => 1 ) if not defined $name;
	pod2usage( -verbose => 1 ) unless -d $path && -w $path;
	sub version {print 'Dancer ' . $Dancer::VERSION . "\n"; exit 0;}

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

	return ($name,$path,$do_check_dancer_version);
}

sub run {
	my $self = shift; 
	$self->_version_check if $self->{do_check_dancer_version};
	$self->_safe_mkdir($self->{dancer_app_dir});
	$self->create_node($self->_app_tree, $self->{dancer_app_dir});
}

sub run_scaffold {
	my $class = shift;
	my $type = shift;
	my $method = "_run_scaffold_$type";
	if ( $class->can($method) ) { $class->$method; } 
	else { die "Wrong type of script: $type"; } 
}
# must change run_scaffold_* for something 
# more intuitive 
sub _run_scaffold_cgi {
	my $self = shift; 

	require Plack::Runner;
# For some reason Apache SetEnv directives dont propagate
# correctly to the dispatchers, so forcing PSGI and env here 
# is safer.
	set apphandler => 'PSGI';
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
	set apphandler => 'PSGI';
	set environment => 'production';

	my $psgi = path($RealBin, '..', 'bin', 'app.pl');
	my $app = do($psgi);
	die "Unable to read startup script: $@" if $@;
	my $server = Plack::Handler::FCGI->new(nproc => 5, detach => 1);

	$server->run($app);
}

sub _validate_app_name {
    my $self = shift;
    if ($self->{appname} =~ /[^\w:]/ || $self->{appname} =~ /^\d/ || $self->{appname} =~ /\b:\b|:{3,}/) {
        print STDERR "Error: Invalid application name.\n";
        print STDERR "Application names must not contain colons,"
            ." dots, hyphens or start with a number.\n";
        exit;
    }
}

sub _set_application_path {
    my $self = shift;
    $self->{dancer_app_dir} = catdir($self->{path}, $self->_dash_name);
}

sub _set_lib_path {
    my $self = shift;
	unless ($self->{appname} =~ /::/) {
		
		$self->{lib_file} = $self->{appname}; 
		$self->{lib_path} = "";
	}
    my @lib_path = split('::', $self->{appname});
    my ($lib_file, $lib_path) = (pop @lib_path) . ".pm";
    $lib_path = join('/', @lib_path);
    $self->{lib_file} = $lib_file;
    $self->{lib_path} = $lib_path; 
}

sub _set_script_path {
    my $self = shift;
    $self->{dancer_script} = $self->_dash_name();
}

sub _dash_name {
    my $self = shift;
    my $name = $self->{appname};
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
        my $file = shift;
		my $root_regex = quotemeta($root);
		$file =~ s{^$root_regex/?}{};
        print $manifest "$file\n";
    };

    $add_to_manifest->($manifest_name);
    $self->_create_node($add_to_manifest, $node, $root);
    close $manifest;
}

sub _create_node {               
    my $self = shift;
    my $add_to_manifest = shift;
    my $node = shift;
    my $root = shift;

    my $templates = $self->_templates;

    while ( my ($path, $content) = each %$node ) {
        $path = catfile($root, $path);

        if (ref($content) eq 'HASH') {
            $self->_safe_mkdir($path);
            $self->_create_node($add_to_manifest, $content, $path);
        } elsif (ref($content) eq 'CODE') {
            # The content is a coderef, which, given the path to the file it
            # should create, will do the appropriate thing:
            $content->($path);
            $add_to_manifest->($path);
       } else {
            my $file = basename($path);
            my $dir  = dirname($path);
            my $ex = ($file =~ s/^\+//); # look for '+' flag (executable)
            my $template = $templates->{$file};

            $path = catfile($dir, $file); # rebuild the path without the '+' flag
            $self->_write_file($path, $template, {appdir => File::Spec->rel2abs($root)});
            chmod 0755, $path if $ex;
            $add_to_manifest->($path);
        }
    }
}

sub _app_tree {
    my $self = shift;

    return {
        "Makefile.PL"        => FILE,
        "MANIFEST.SKIP"      => FILE,
        lib                  => {
         $self->{lib_path} => {
            "$self->{lib_file}" => FILE,}
        },
        "bin" => {
            "+app.pl" => FILE,
        },
        "config.yml"         => FILE,
        "environments"       => {
            "development.yml" => FILE,
            "production.yml"  => FILE,
        },
        "views" => {
            "layouts"  => {"main.tt" => FILE,},
            "index.tt" => FILE,
        },
        "public" => {
            "+dispatch.cgi"  => FILE,
            "+dispatch.fcgi" => FILE,
            "404.html"       => FILE,
            "500.html"       => FILE,
            "css"            => {
                "style.css" => FILE,
                "error.css" => FILE,
            },
            "images"      => {
                "perldancer-bg.jpg" => sub { $self->_write_bg(catfile($self->{dancer_app_dir}, 'public', 'images', 'perldancer-bg.jpg')) }, 
                "perldancer.jpg" => sub { $self->_write_logo(catfile($self->{dancer_app_dir}, 'public', 'images', 'perldancer.jpg')) },
            },
            "javascripts" => {
                "jquery.js" => FILE,
            },
            "favicon.ico" => sub { $self->_write_favicon(catfile($self->{dancer_app_dir}, 'public', 'favicon.ico')) },
        },
        "t" => {
            "001_base.t"        => FILE,
            "002_index_route.t" => FILE,
        },
    };
}

sub _safe_mkdir {
    my $self = shift;
    my $dir = shift;
    if (not -d $dir) {
        debug ("Writing directory: $dir\n");
        mkpath $dir or die "could not write the directory $dir: $!";
        debug ("Successfully wrote the directory: $dir\n");
    }
    else {
        debug ("Not Writing directory: $dir\n");
    }
}

sub _write_file {
    my $self = shift;
    my $path = shift;
    my $template = shift;
    my $vars = shift;
    die "no template found for $path" unless defined $template;

    $vars->{dancer_version} = $self->{dancer_version};

    # if file already exists, ask for confirmation
    if (-f $path && (not $self->{do_overwrite_all})) {
        print "! $path exists, overwrite? [N/y/a]: ";
        my $res = <STDIN>; chomp($res);
        $self->{do_overwrite_all} = 1 if $res eq 'a';
        return 0 unless ($res eq 'y') or ($res eq 'a');
    }

    my $fh;
    my $content = $self->_process_template($template, $vars);
	debug ("Writing file: $path\n");
    open $fh, '>', $path or die "unable to open file `$path' for writing: $!";
    print $fh $content;
    debug ("Successfully wrote: $path\n");
    close $fh;
}

sub _process_template {
    my $self = shift;
    my $template = shift;
    my $tokens = shift;
    my $engine = Dancer::Template::Simple->new;
    $engine->{start_tag} = '[%';
    $engine->{stop_tag} = '%]';
    return $engine->render(\$template, $tokens);
}

sub _write_data_to_file {
    my $self = shift;
    my $data = shift;
    my $path = shift;
	debug ("Writing file: $path\n");
    open(my $fh, '>', $path)
      or warn "Failed to write file to $path - $!" and return;
    binmode($fh);
    print {$fh} unpack 'u*', $data;
    debug ("Successfully wrote: $path\n");
    close $fh;
    return 1;
}

sub _send_http_request {
    my $self = shift;
    my $url = shift;
    my $ua = LWP::UserAgent->new;
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
    my $self = shift;
    my $latest_version = 0;

    my $resp = $self->_send_http_request('http://search.cpan.org/api/module/Dancer');

    if ($resp) {
        if ( $resp =~ /"version" (?:\s+)? \: (?:\s+)? "(\d\.\d+)"/x ) {
            $latest_version = $1;
        } else {
            die "Can't understand search.cpan.org's reply.\n";
        }
    }

    return if $self->{dancer_version} =~  m/_/;

    if ($latest_version > $self->{dancer_version}) {
        print qq|
The latest stable Dancer release is $latest_version, you are currently using $self->{dancer_version}.
Please check http://search.cpan.org/dist/Dancer/ for updates.

|;
    }
}

sub _download_file {
    my $self = shift;
    my $path = shift;
    my $url = shift;
    my $resp = $self->_send_http_request($url);
    if ($resp) {
        open my $fh, '>', $path or die "cannot open $path for writing: $!";
        print $fh $resp;
        close $fh
    }
    return 1;
}

sub _templates {
    my $self = shift;
    my $appname    = $self->{appname};
    my $appfile    = $self->{lib_file};
    my $lib_path   = $self->{lib_path};
    my $cleanfiles = $self->{appname};
	unless($lib_path eq ""){ $lib_path .= "/"; } 

    $appfile    =~ s{::}{/}g;
    $cleanfiles =~ s{::}{-}g;

    return {

'Makefile.PL' =>
"use strict;
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
'index.tt'  => 
'  
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
              You can add some routes to <tt>lib/'.$lib_path.$self->{lib_file}.'</tt>. 
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

'main.tt'   =>
'<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN"
        "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
<meta http-equiv="Content-type" content="text/html; charset=<% settings.charset %>" />
<title>'.$appname.'</title>
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

"dispatch.cgi" =>
"#!/usr/bin/env perl
use Dancer::Script;

Dancer::Script->run_scaffold('cgi');

",


"dispatch.fcgi" =>
"#!/usr/bin/env perl 
use Dancer::Script;

Dancer::Script->run_scaffold('fcgi');
",

"app.pl" =>

"#!/usr/bin/perl
use Dancer;
use $appname;
dance;
",

"$self->{lib_file}" =>

"package $appname;
use Dancer ':syntax';

our \$VERSION = '0.1';

get '/' => sub {
    template 'index';
};

true;
",

'style.css' =>
'
body {
margin: 0;
margin-bottom: 25px;
padding: 0;
background-color: #ddd;
background-image: url("/images/perldancer-bg.jpg");
background-repeat: no-repeat;
background-position: top left;

font-family: "Lucida Grande", "Bitstream Vera Sans", "Verdana";
font-size: 13px;
color: #333;
}

h1 {
font-size: 28px;
color: #000;
}

a  {color: #03c}
a:hover {
background-color: #03c;
color: white;
text-decoration: none;
}

#page {
background-color: #ddd;
width: 750px;
margin: auto;
margin-left: auto;
padding-left: 0px;
margin-right: auto;
}

#content {
background-color: white;
border: 3px solid #aaa;
border-top: none;
padding: 25px;
width: 500px;
}

#sidebar {
float: right;
width: 175px;
}

#header, #about, #getting-started {
padding-left: 75px;
padding-right: 30px;
}


#header {
background-image: url("/images/perldancer.jpg");
background-repeat: no-repeat;
background-position: top left;
height: 64px;
}
#header h1, #header h2 {margin: 0}
#header h2 {
color: #888;
font-weight: normal;
font-size: 16px;
}

#about h3 {
margin: 0;
margin-bottom: 10px;
font-size: 14px;
}

#about-content {
background-color: #ffd;
border: 1px solid #fc0;
margin-left: -11px;
}
#about-content table {
margin-top: 10px;
margin-bottom: 10px;
font-size: 11px;
border-collapse: collapse;
}
#about-content td {
padding: 10px;
padding-top: 3px;
padding-bottom: 3px;
}
#about-content td.name  {color: #555}
#about-content td.value {color: #000}

#about-content.failure {
background-color: #fcc;
border: 1px solid #f00;
}
#about-content.failure p {
margin: 0;
padding: 10px;
}

#getting-started {
border-top: 1px solid #ccc;
margin-top: 25px;
padding-top: 15px;
}
#getting-started h1 {
margin: 0;
font-size: 20px;
}
#getting-started h2 {
margin: 0;
font-size: 14px;
font-weight: normal;
color: #333;
margin-bottom: 25px;
}
#getting-started ol {
margin-left: 0;
padding-left: 0;
}
#getting-started li {
font-size: 18px;
color: #888;
margin-bottom: 25px;
}
#getting-started li h2 {
margin: 0;
font-weight: normal;
font-size: 18px;
color: #333;
}
#getting-started li p {
color: #555;
font-size: 13px;
}

#search {
margin: 0;
padding-top: 10px;
padding-bottom: 10px;
font-size: 11px;
}
#search input {
font-size: 11px;
margin: 2px;
}
#search-text {width: 170px}

#sidebar ul {
margin-left: 0;
padding-left: 0;
}
#sidebar ul h3 {
margin-top: 25px;
font-size: 16px;
padding-bottom: 10px;
border-bottom: 1px solid #ccc;
}
#sidebar li {
list-style-type: none;
}
#sidebar ul.links li {
margin-bottom: 5px;
}

h1, h2, h3, h4, h5 {
font-family: sans-serif;
margin: 1.2em 0 0.6em 0;
}

p {
line-height: 1.5em;
margin: 1.6em 0;
}

code, tt {
    font-family: \'Andale Mono\', Monaco, \'Liberation Mono\', \'Bitstream Vera Sans Mono\', \'DejaVu Sans Mono\', monospace;
}

#footer {
clear: both;
padding-top: 2em;
text-align: center;
padding-right: 160px;
font-family: sans-serif;
font-size: 10px;
}
',

# error.css
"error.css" =>

"body {
    font-family: Lucida,sans-serif;
}

h1 {
    color: #AA0000;
    border-bottom: 1px solid #444;
}

h2 { color: #444; }

pre {
    font-family: \"lucida console\",\"monaco\",\"andale mono\",\"bitstream vera sans mono\",\"consolas\",monospace;
    font-size: 12px;
    border-left: 2px solid #777;
    padding-left: 1em;
}

footer {
    font-size: 10px;
}

span.key {
    color: #449;
    font-weight: bold;
    width: 120px;
    display: inline;
}

span.value {
    color: #494;
}

/* these are for the message boxes */

pre.content {
    background-color: #eee;
    color: #000;
    padding: 1em;
    margin: 0;
    border: 1px solid #aaa;
    border-top: 0;
    margin-bottom: 1em;
}

div.title {
    font-family: \"lucida console\",\"monaco\",\"andale mono\",\"bitstream vera sans mono\",\"consolas\",monospace;
    font-size: 12px;
    background-color: #aaa;
    color: #444;
    font-weight: bold;
    padding: 3px;
    padding-left: 10px;
}

pre.content span.nu {
    color: #889;
    margin-right: 10px;
}

pre.error {
    background: #334;
    color: #ccd;
    padding: 1em;
    border-top: 1px solid #000;
    border-left: 1px solid #000;
    border-right: 1px solid #eee;
    border-bottom: 1px solid #eee;
}

",

"404.html" =>
    Dancer::Renderer->html_page(
        "Error 404",
        '<h2>Page Not Found</h2><p>Sorry, this is the void.</p>',
        'error'),

"500.html" =>
    Dancer::Renderer->html_page(
        "Error 500",
        '<h2>Internal Server Error</h2>'
                 . '<p>Wooops, something went wrong</p>',
        'error'),

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

'jquery.js' => $self->_jquery_minified,

'MANIFEST.SKIP' => $self->_manifest_skip,

'development.yml' =>
"# configuration file for development environment

# the logger engine to use
# console: log messages to STDOUT (your console where you started the
#          application server)
# file:    log message to a file in log/
logger: \"console\"

# the log level for this environement
# core is the lowest, it shows Dancer's core log messages as well as yours
# (debug, warning and error)
log: \"core\"

# should Dancer consider warnings as critical errors?
warnings: 1

# should Dancer show a stacktrace when an error is caught?
show_errors: 1

# auto_reload is a development and experimental feature
# you should enable it by yourself if you want it
# Module::Refresh is needed 
# 
# Be aware it's unstable and may cause a memory leak.
# DO NOT EVER USE THAT FEATURE IN PRODUCTION 
# OR TINY KITTENS SHALL DIE WITH LOTS OF SUFFERING
auto_reload: 0
",

'production.yml' =>
'# configuration file for production environment

# only log warning and error messsages
log: "warning"

# log message to a file in logs/
logger: "file"

# don\'t consider warnings critical
warnings: 0

# hide errors 
show_errors: 0

# cache route resolution for maximum performance
route_cache: 1

',

"001_base.t" =>
"use Test::More tests => 1;
use strict;
use warnings;

use_ok '$appname';
",

"002_index_route.t" =>
"use Test::More tests => 2;
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

sub _write_bg {
    my $self = shift;
    my $path = shift;
    my $data =<<'EOF';
M_]C_X``02D9)1@`!`0$`2`!(``#_VP!#``4#!`0$`P4$!`0%!04&!PP(!P<'
M!P\+"PD,$0\2$A$/$1$3%AP7$Q0:%1$1&"$8&AT='Q\?$Q<B)"(>)!P>'Q[_
MVP!#`04%!0<&!PX("`X>%!$4'AX>'AX>'AX>'AX>'AX>'AX>'AX>'AX>'AX>
M'AX>'AX>'AX>'AX>'AX>'AX>'AX>'A[_P``1"`'T`?0#`2(``A$!`Q$!_\0`
M&0`!``,!`0````````````````(#!`$(_\0`*Q`!``("``4#!`,!`0$!````
M``$"`Q$$$B$Q,C-!41,B87$C0E(48H%#_\0`%`$!````````````````````
M`/_$`!01`0````````````````````#_V@`,`P$``A$#$0`_`/2H````````
M````````````````````````````````````````````````````````````
M````````````````````````YN#<?(.CG-'S!N/D'1S<?+H`````````````
M``````````````````````````````````````3T5VRUCWZ@L<W'RSVS3VA7
M-IGW!JMDK"$YZ^S/N7`73GGV1G->?=`!*<EI]W.>WRY$2[R6^`.:3FGY=BEI
M]G)I8#GM\NQDM'NYRRY,2"R,U_E*,_RI<!JKFK*=;1/NQ.[GY!N&.N2U5U,\
M?V!<(UO6W:4@```````````````````````````````````````GHJR98KVZ
M@LF8B-RKOFB/'JHM>UI[H`G?):WNB1&^R=,5K>V@5I169[0OKBK7REV;TKXQ
"$@H`
M:XK3WA9&"/>7>>]NU9@C'>W>TP!R8Z^[O-BCX(Q?,[2C'3X!'ZE/:(<^K'^8
M6<E/\G+7X!7.2?:I]3_RMY:_!RU^`5?5CWB'?J8_>(3Y*_Y@Y*?Y@$/XI]X<
MG%2W:4IQ5]NCDXI]K:!"V"8[=5<X[Q[+=9*^\R[]6W:U`9YC3C5_':/:)1M@
M]XD%$3,=I64S3'24+4M7O"(-E<E;>_5-AB9CLLQYICOU!J$:7BT=)2``````
M```````````````````````````1M:*QN4<F2*_MFO>;3N03R99MTCI"MQ.E
M)MV!&(WV64PS;K/1;6E,<;GNC-[7G5.@)17'2/:9<G):W2L3#M<6^MNZR(B(
MU`*HQVGRE.N.L=H3`````````````')B)[N@*[8JSVZ2A,9*>^X7@*8R1;I:
M-%L5;>,PLM2MNZJ:7IUK/0%5Z36>R#57)%OMM'5#)A]Z@IK,UG<-&++$])9Y
MB8GJX#>,N++->D]FFMHM&X!T```````````````````````````!3ERZZ1W<
MS9==(4`3,S/4(B9G4-&/'6D<U@1Q8M];)VR17[:1U1M:UYU6.BS'CBL?,@A7
M'-IW>5L1$1J'0`<M.HVY6T2"3EIU#J-XW`(UO.^KO-//HIJ8_+G_`.H.Q:>;
<16TS:8E'^^W:=Y`M>=ZAV;?;N'*QN\NVCEIH"@``
MVM,]DT*3$]$Y!7SSS?A.;=-H6B*__7;>,`5M,SJ2]IB=1W1CR=MZD`E2VXZH
MS>=_ARGN>T@LK.XVZCC\(2`$(O&])@A?'%OPK^_'^E[DQON"N8IEA1DI-)ZK
MKXYB>:KM;Q;[;QJ094\=YK*67%->L=E0-M+Q:.B3%2TUG<-6.\7C\@F`````
M```````````````````ISY-1J'<V3EC4=V:9W.P)ZNUK-IU#E8F9U#32L8Z;
MGN!2M<==SW1^[+;X@K%LEMSV71$1&H`K6*QJ(=```'+1N-(TIRI@#EITZY:-
MP"$]+;@CU/\`X[6D[ZR[R_?L$)Z[,?NG%>KE:ZF9!&LZO,NVGFIMVU-SN)=F
MOVZ@'*1":%:VB>Z4]@0\K?IW)VASDM$[B4];KJ05QY.V]2':TF)W,NWKOK'<
M$<?NY;4Q,IUKJ$9I.^_0$L?A"3D1J-.@A%/NVF```"O)CB>L=)6`*:7U/+='
M+BU]U>RW)2+1^4,=IK/)?L#.ECM-9VGGQZ^ZO92#;2T6C<),>*\UG\-=9BT;
M@'0```````````````````$<EHK7<NS.HVRYK\UOP"-K3:=RY$;EQ?@IK[K`
MECI%*\TN1O+?\%IG)?4=H75B*QJ`(B(C4.N6G4;9YSWW[`TC-]>_X/KW_`-(
MSQGGW3KFK/<%HY$Q,='0`49,UJWF([`O&;Z]_P`'U[_@&D9OKW_!]>_X!I&;
MZ]_POQS-J[D$@0RVFM=P"8S?7O\`@^O?\`TC-]>_X=C//N#0*JYJSW61,3V!
MT``%.7+:DZ@%PS?7O^':Y[S,1T!H``0R4YH_*8"G';^EE>;'RSN.R[+3<;CO
M#F.T7KRV[@RKL%^6=3V0R5FMM(`WP*<%]QJ5P`````````````````(WGEK,
M@KXB^HU#,E>>:VW(C<Z!/#3FM^%N6W:E78UBQ_DPU[VD$L=>6OY3`$;^,L<]
/VR_C+'/<'`68L?/OKK0*
MQ;;%KM.U<QKN">/)-9::6BT;AB6\/;5N7Y!JADS^K+6R9_5D%8)XZ\]M;T"`
MO^A'^SZ,?[!3'=KP^G"KZ,?[78XU70)*\_@L5Y_`&0``74Q1;'S3.G+8ICM.
MP5IX\DUG\(.`W5M%HW#K/PUNNF@!EXCRAJ9>(\H!4E3RC]HI4\H_8-H```"G
*+6:SSU7.3&XT"@``
M[1&7'N.[-,:G2^/X\FO:7.(I_:.P*J6Y;1+72W-6)8EW#WU.I!I`````````
M```````9^(O[0OO/+698[SNTR"*_AZ?VGLIK&YB&F\_3QQ$`C/\`)DU[+HC4
M:0PUY:_M8``"-_&6.>[9?QECGN#C1PO]F=HX3W!;RQ[,_$5U?;4S\2"A*DZM
2M$!NIUK$LN?U9:<7A5FS^K(*
MUO#^HJ6\/Z@-,UC?9SEK\)2`CRU^$HZ``KS^"Q7G\`9``:\$1.*-I<NNR/#^
MDL!DS5Y;*U_%^4*`3Q3JT-C%3RC]MH#+Q'E#4R\1Y0"I*GE'[12IY1^P;0``
M```0RUYJ_E''//6:RM47^S)$QV!3>O+:8<B=3M?Q%=Q%H9P;,5N:NTV;A[:M
MJ6D``````````````%/$VU&F99FMS60B-SH%W#UZ[EWSRZ]DH^S#^3!'V[]P
M6@```C?QECGNV7\98Y[@XT<)[LZ[AK5KOFG0-+/Q,]=)VS5B.C/>TVG<@B[6
M-SIQ9AKN\?`-6/I6(9<_JRUPR9_5D%:WA_4A4E6TUG<`VC)]6Q]6P-8CBG=(
MF4@%>?P6*\_@#(`#7P_I+%&+)%<>G,F:>T`CGMS65.SUEP$\4;M#8S\-7WEH
M`9>(\H:F7B/*`5)4\H_:*5/*/V#:``````AEKS4GY3`58YYJ32?9GO'+:87>
M&7]N<374\WR"FLZF);:SN&%IX>VZZ!<````````````CEGEIM)3Q,_;H&>>L
MI88W>$&CAHUN9!W-.[16%M8U&E-/NS6E>````"-_&6.>[9?QECGN#@.Q$SV@
M'!.*6GV3KA]YD%5:S:=0U8J16"E8CM&DX!V&3/ZLM<,F?U9!6"6.O/;4`B+O
MH3_J#Z$_Z@%V'TH31QQRTB$@%>?P6*\_@#(``+*XIM7FVA:-3H'%F*G-/Z5K
M>'G5M`T4C4)``R\1Y0U,O$>4`J2IY1^T4J>4?L&T```````%6>.D6^"?OQ;3
$O&ZS"@``
M\/::@SK,$ZNADC5M.5G4[!N'*^,.@``````````,W$SN[3/9CRSNP(-5?MPS
M/X9JQN6G)TQQ`&".G-\K4,4:I"8````(W\98Y[ME_&6.>X.-'"]K:[L[1PGN
5"S5O?3O+'ND```0R9_5EKADS^K(*
MUO#^HJ6\/Z@-$TC9R52D!R(U&G0`5Y_!8KS^`,@`->"-XH4\1&KKN'])#B8]
MP9TL<ZO"+L=)!MB=QMU#%.Z1*8#+Q'E#4R\1Y0"I*GE'[12IY1^P;0``````
M`%,?;FG\KE.;I:)^9!#B8^_:IHXF/LB68&O#.ZK%/"S]LPN``````````!R>
MD2Q6[RV9)U5CGN"6*-WA=G\JPJP1_)"S)URU_8+HC4.@````"-_&6.>[9?QE
MCGN#C1PGNSM'">X+P```(9,_JRUPR9_5D%:WA_45)X[\EN;6P;)%'_1_Y/\`
MH_\`(+Q1_P!'_E;2W-78)*\_@L5Y_`&0`&OA_2=S1O',.</Z2<QN-`Q2XE?I
M:40:>'G==+F;AIU:6D!EXCRAJ9>(\H!4E3RC]HNUZ6@&X5?6J?5J"T5?5JG2
MT6[`D````JSQN(6H9?$$,GW8F=IKUPLT]P6\-/732R8)_DAK``````````!#
M-X,DM6?P99!;P\?<E/7*CPW=./5_^@N`````!&_C+'/=MM&XTSS@MOO`*6CA
M/=#Z%OF%N"DTWL%H```$,F?U9:U&3%:UYF)@&<6_0M\P?0M\P"H6_0M\P?0M
M\P"N.[7A\(4_0M\POQQRUU()*\_@L0RUFU=0#&+?H6^8/H6^8!=P_I+$,59K
M34I@RYXU94U9Z3>8TJ^A;Y@$<<ZM#8SUP6BT3.D\]^6NH[@M9>(\H3P7F9U+
MN;'-YW&@9A;]"WS!]"WS`*A;]"WS!]"WS`*FGANTJ_H6^878:36)V"P```!'
()X2DY?PG]`H`
M\/HRS3WEIP>G+-/>02P^I#8QX?4AL``````````!7G\&66O-X,D@MX;R2CU9
M1X?R2_\`U_\`H+P`````)1Y(^92GM,L\\1;?:`7<D?,NUC2C_HM\0[&?Y!>(
MUO6W:4@`1O/+69!)&:Q,[W*G_HGX@C/:9UJ`7<D?,G)'S+L3N-N@CR1\R<D?
M,H9,LTG40C7/,VB)B`6\D?,NQ&H=1R6Y:[B`2<F-PH_Z+?"[';FC8.<L1[R[
MR1\RJS[BT3M96T13>P2Z5@BT3/26;+DFT].R-+3%NX-=HVYRQ'7;DY*Q6.O5
M1DRS;I`+;Y:UC4=U6K9;;=QXIM.[++WKCC4=P2QTBD:]W;5B94?7M\)X\LWM
MJ8!9R1\R<D?,HYLDXYC4;5_]%OB`7<D?,G)'S*F.(GWA93+%NX)<D?,NUC3H
M`````Y?PG].HY/"00P>G+-/>6G#Z4LT]Y!+%ZD-D,>'U(;```````````0R>
M+)/=MMUK+%/>06<//\D)Y.F6%6&=9(79_.L@N'(ZPZ````#D^,_IBGO+;/:?
MTQ3WD!Q9AB)M&T\U(UN(T"JEIK,=6ND\U=L33P\_;H%RO//\<PL4\1/30,SL
M=W`&W%.Z0DKX>?XU@,O$>4*XG4[6<1Y0J!MQSND2CG\'.'G==.Y_`&7W:L/@
MR^[5A\`0XF)Z*HO.M-62(FDL<@X`#LS,]U^#'TYK*\->:T?#3?ICF(]@59<N
MOMJHF9F>I/5;@K69ZQL%*WA_.%O+3_#M(KOI70(<7WAG:.+]E$=P".C12E9Q
M]E%Z\LZ!?@ON-2N9,,ZR0U@````(9?%-7GG40#E.F%FGNT7Z86<$\'J0ULW#
MQ]VVD``````````">S%DC5FUEXB-7!"DZMM?EZTB69JC[L.OP">.=TB4E6"?
MLTM````!R?&?TQ3WEMGQG],4]Y!9P_G"_+&Z2HX?SAHR>G8&)?PW=0NX6?OT
H#2S\5/6(:&7B)W8%8ECC=G,GG(+^&G[=+F?AI^[30#+Q'E"I;Q'E"@``
M@7<-.K+<_@S4G5H:<T[Q[!E]VK#X,ONU8?`$LDZI+&U9YU5D`=<2QQNVI!IP
MUY:I9/3L[$:B(<R>G8&)?PWDH7\-Y`T``HXOV41W7\7[*([@UX?3A3Q/3(NP
7^G"CB)W<$,?E#97M#'C\X;([`Z````H`
M<_6U8_*Y3Y9ICX`XF=4B&9=Q,_=I4"_A8Z3*]7@C55@``````````"CB8Z;7
MH9HW28!C:.&G<3"B>Z>&VKP"W']N6T2N49HY;Q:/==$[@'0```<GQG],4]Y;
M9\9_3%/>06</YPT9/3LS\/YPT9/3L#$NX7U%*[A?4!I8\L[M+7:=0Q6\I!9P
M\;LYG]24^%C<RYQ$?=L'.'G5VICQSJS9'8&7B/*%<1N=+.(\H0Q>I`$QRV73
,.\$2KSQJ\NUG^/0*
M_=JP^#+[M6'P!'B>D0S-/$]H9@%F#SA6LP>I`-:.3T[)(Y/3L#$GCR32=Q"`
1"_\`Z+?$+XG<1+%#;7PC]`H`
M>+]E$+^+]F<%]<O+CTIM.YVXZ"S!7=M_#4ACK$5C7NF````#EIU6958>\V2S
M6U77RYX80499W?:,1N24\$;N#52-5AT`````````````8\D:M*,3J=K^)K[P
MS@U3]^*)=P6W37NAP]M[K)'V9=>P+P```<GQG],4]Y;9\9_3%/>06</YPT9/
M3LS\/YPT9/3L#$NX7U%*_A8^[8+<LZI+)/=JXB?XV0&GAM1$]=(\1J>TJ0".
M\-M9W$,4=VO%.Z@HXCRA#'ZE?VGQ'E"&/U*_L%W%1VE1$M>:-U9`/=JP^#+#
M5A\`=RUB:3/PR->68BDQ\L8"WA_45.UF8G<`W(Y/3L8[<U8,GIV!B6X:Q:>J
MI?PWD"7)7_*V.QIT%'%^RB.Z_B_91'<%MJQ]*)B.JKW:8C>%FGN#7AG=$U/#
M3NLK@```1R3RUF056^_+'X.)M[0[AC43>?=3DGFO,@@T<-7IM1'66S'7EKH$
M@`````````````1R1S5F&.T:F8;F;B*ZG?R"NDS%H7YHYJ1:&9HX>VXY9!9B
KMS5341_'DU[+P``<GQG],4]Y;9\9_3%/>06</YPOS3JDPS8[<L[=RY9N"@``
MVCAHZ[4-6"-4_((\3/33.NXJ?OTJKY`E&&\QO1;%:L;EHBNZQU+UU6>NP9&G
GAIWC9I7\-/30(<1Y0AC]2O[3XCR0Q^I7]@V6ZQ+'>-6TVLO$1JX*
MX:\,?8RTCFMIIR6Y,>O<%7$7W.H]E+LSN=D1N0<$YQVBNYA`%_#WU/+\KLGI
MV8ZSJVVN-7QZ^08U_#>2&3':OZ<QY)I.X@&P9_\`HM\0ECRS>VI@'.+]E$=U
M_%^RB.X->.-XF2T:F6O#Z3-EC5@6<-/730R8)UDAK```4Y9YKQ6.RS);EKM7
MBC43>P&:>2D59D\MN:THQUG0+.'KNW7LU*\->6BP``````````````!')7FK
M*0##:-3IVDS6VX7<13^T,X-5HC)CW'=W#;<:GO"K!?4ZGLGDCEMSU[`N$:6B
MT;2!R?&?TQ3WEN5<M/\``,KNI^&GEI_@B(]JZ!5CQS,[GHTQTAR(^4@9,\[N
MCC\X:+13?6NRL4WTIJ061V+>,ND]@8;1J5O#3]VEDUI[T=I%8MTKJ05<3YJ\
<?J5_;3>*S/6NW*Q3<:IH%JGB8^W:Y&\1,=8V"@``
M>&KO[D<]MV:*1$5^V-,E_*0178N2O6=*0&R;TF-3++DB(MT1=@'$JWM7M*RN
M/GKN.BNU9K/6`:,=XR1J5.:O+?4)<-&[2MO%9GK78,BW!YPMY:?X=I%=]*Z!
4#B^\*([M>2*SKFKM'EI_@$L/IPH`
M.)C5VFNHCHC>*S/6NP9:3JT-E>M85\M/\+([`Z"K-?\`K7N",_R9->QGMRUY
M82C6*FY[L]IYIV"*W!3FMOX5UC<Z:\=>6OY!,`````````````````'+1N-,
MF2O+;38AEIS5!D:,-XO7ELSS&IT5F:SN`7QO'?\`$KHG<;A7$QEI^4:6FEN6
MW8%X```````````````"NV.EIVL1FL2"$8:._1QI<GY.2/F00MAIK[>[/>DU
MG4M<5UV0XB-TW[@[AC5.CF>-TVEBC5#-X2"KA9ZS#0S<-Y2T@```````C>T5
MC8.9+16OY0Q5_O9RE9O;FMV<SY/ZP"&:_-;IV5BS#3FMOV!9P]/>5[D1J-.@
<````````````````````ISX]QS0SMS/FQZZP"@``
MJ6FL[AHG66OY9DJ7FL@NQWFD\MERK[<M>G=&EII/+;L"\<B8F-PZ````````
M`#FX^0=``')F([R;CY!T<W'R;CY!URVM=3<.]P<CL6C<:EUR>P(TI6L]$W*Q
MIT`````$;WBL?D"]HK&Y55B<EMSV*UG)/-;L9<D5CEJ!FR16.6J@F=]RL3:=
M0#M*S:=0UTK%8TYBI%8_*8``````````````````````#DQN'0&;-BF)W"IN
MGJSYL7O`*J6FL[AHB:Y:]>[,1,Q.X!?]V.?F%M+1:.BK'EBWVV=M2:SS4D%P
MJIEB>ENZT`````57F>;IV65WH'4(US)JX\I!*;1$Z=CJKZ1;JLB-1T!#)&[0
M[-8BG1S)OFZ.]8IU!'^KENT._P!7+>,`[,[TMA3VG2Z`!R_CT0QS.P6````#
MEK16.LJ9O:\ZH">3)KI'64:TF?NO+L5KCC=NZK+EFW2.P)9<O3EJIGJXE6LV
MG4`Y6)F=0U8L<5C?N8L<4C\K`````````````````````````````4Y<6^M>
M[/,3$ZEN0R8XM`,BS'EFO2>R-\=JSVZ(`U:IDCITE'[\<_A1$S':5U,WM:`6
D5RUM^UBJ:TOXSI'^2G:-P"\55RQ_;HLK:)[2#N@`%<>4K#0*
MK3N=2LKVZFH^'05W\X3M&ZN@*=^SMHUJ%FH^#4`KO'WK8`!S3H`(VO6.\JYR
M6GQC8+9F(C<JK9=]*$8[6ZVF8=FV.D=-;!RN.;?=>2V2M(U7NKR99MVZ*P=O
M>;3N478C:W'AF>MN@(8Z3:>W1II2*QT2K$1&H=``````````````````````
M``````````!R8B>ZG)A]X7@,-JS'>'&VU*V[PIOA]X!3%ICM*ZF;VF-JIK,=
MX1!JB<=N^HER<<]ZV9TJY+1[@MWDK[3*499]ZZ0KGUWZI1>EN\`G&2D^[O-7
MYA#DQ3\.?3C^LP"W<?+JGZ=_:Q]/)_L%PIY<W^CDRSWL"YSFCY5?3R?[/IS[
MV!9ST_U",Y:^W5SZ=/>8-8J]H!R<MI[4<Y<EO>8=G-6.D0A;-:>W0$XQUKY3
MLMDI7QB%%K3/>4067RVM^$)ZB5,=K?@$$Z8[6GLOIAB._59$1$=`0ICBL=>J
MP```````````````````````````````````````1M6+=X5WP1/BN`9+8K50
MU/PW(VI$^P,3K1;!7V0MAGV!4[%ICW2G%:/9&:3'L#L9+1[N_5O\H3$P`L^M
M?Y<G-?Y0`3^K?Y<F]I]T2*R!,S(E&.T^R48;_`*G5U<'RLKAK`,T5F9[+*X;
M3U:(B(]G05UQ5CVZK(Z`````````````````````````````````````````
M`````````YJ/AT!SEK\0<M?B'0$>2OP12OQ"0#G+7X@Y8^(=`<U#H```````
M````````````````````````````````````````````````````````````
M````````````````````````````````````````````````````````````
M````````````````````````````````````````````````````````````
<``````````````````````````````````__V0``
EOF
    $self->_write_data_to_file($data, $path);
}

sub _write_favicon {
    my $self = shift;
    my $path = shift;
    my $data =<<'EOF';
M```!``$`$!````$`"`!H!0``%@```"@````0````(`````$`"```````````
M```````````````````````("`D`%103`!D7%0`;&A@`'1L9`!X<&@`E)"(`
M)B0B`"<E(@`G)2,`*"8C`"DG)0`J)R4`*2@E`"TJ)P`P,"P`,S$O`#0Q+P`T
M,BX`-#(O`#4R+P`V,S``-34R`#DU,0`W-C,`.38S`#DW,P`[.#0`/SPW`#X\
M.``_/#D`/STY`#\].@!#/SL`14(]`$9#/P!'1#\`2$0_`$=$0`!)1D(`3$A$
M`$U*10!-2D8`34M&`%!-20!23DH`4T]*`%-/2P!:5U$`75E3`%];5@!E85L`
M9F%<`&9C7P!I9%X`9V1@`&EE7P!H96``:&5B`&IG8@!N:6,`<&MD`'!L9`!S
M;F<`=W)J`'=R:P!X<VL`=W-L`'ET;`!W='$`=W5O`'MW;P!\=W``?7=Q`(!Z
M<P"!?'8`?WQY`(1^=@"$?G<`A']X`(:!>0"%@GX`B8-Z`(>$@0")AH(`CXF!
M`(^,AP"3C80`DXV%`)"-B`"5CX8`D8Z+`)B3B0"<EXX`HIN3`*6=DP"FGY<`
MIZ*8`*BBF`"JI)P`JZ:<`*ZFFP"OJ)\`L*F@`+"JH`"SK*,`MJ^E`+>PI@"W
ML*<`N;&G`+6RK0"[LZ@`N[2J`+BTK0"\M:L`OK:M`+FVL0#!N:T`P;FN`,*Z
ML0##N[``PKNQ`,2\L`#$O+$`P[RR`,*^N`#&O[0`R,"V`,K!MP#)P;@`R\*V
M`,K#N0#/QKH`T<B[`-#)O0#4RKP`ULN^`,W*Q0#4S,$`U<V_`-7-P@#7SL(`
MU\_"`-C/PP#7S\0`U\_%`-G1Q0#9U<X`W]?,`-S9TP#CVLX`W=G4`.?=T`#@
MW-<`Y=W2`.#<V`#GWM$`Y]_2`.C?T@#BWM@`X]_9`.G@U`#JX=0`X^#;`.OB
MU0#KX]4`[./5`.OCU@#LX]8`[>37`.;CW@#HX]\`[N77`.WEV`#NY=D`[^;8
M`/#GV`#PY]D`\>?9`/#GV@#PY]P`\>C;`/+IVP#T[-\`\.OF`/#LY@#X[N``
M^>_B`/SRY0#X].\`^O?R`/[[]@#__/<`_?W]`/[]_0#]_?X`_?[^`/__^@#^
M_OX`_?[_`/[__P#___\`````````````````````````````````````````
M````````````````````````````````````````````````````````````
M````````````````````````````````````````````````````````````
M````````````````````````````````````````````````````````````
M````````````````````````````````````````````````````````````
M````````QLG&P<F)13LY3)G)P<;)R<G&R)47,7N$A6\I);C$QLG&R'$:B["'
&=5J(KX(*
ID\3&P9\;LJ2FNK%Z7XZLF`R^PLD<CS-!30-5#@DF1$IV,LF7+;9#1PH`
M+PT]7"`P6*04P%%JHDA!"TX2/E)&0D&E3VXUC*%=9E"`9&4V)%=_GFA6-8VG
M'ZAK`6($26T`0*AG651IJ2=X<#B["!.\&+6G2W2C*K<H*S\&G049DA:NK1'%
MR2*1(RD\'18,"%88/LW(TR<&K$GY\FF%_9WRT>90(O\+&QGT0BI9><W=@G($'
MH,/&R<;'JB$L;)&08QXNO</&R<;)QL')FU,W.ENYR<3&R<D`````````````
M````````````````````````````````````````````````````````````
)````````````
EOF
    $self->_write_data_to_file($data, $path);
}

sub _write_logo {
    my $self = shift;
    my $path = shift;
    my $data =<<'EOF';
M_]C_X``02D9)1@`!`0$`2`!(``#__@`30W)E871E9"!W:71H($=)35#_VP!#
M``4#!`0$`P4$!`0%!04&!PP(!P<'!P\+"PD,$0\2$A$/$1$3%AP7$Q0:%1$1
M&"$8&AT='Q\?$Q<B)"(>)!P>'Q[_VP!#`04%!0<&!PX("`X>%!$4'AX>'AX>
M'AX>'AX>'AX>'AX>'AX>'AX>'AX>'AX>'AX>'AX>'AX>'AX>'AX>'AX>'A[_
MP``1"`!``$`#`2(``A$!`Q$!_\0`&P```@,!`0$`````````````!@<$!0@#
M`0+_Q``W$``!!`$"`P4%!P0#`0`````!`@,$!1$`!@<2(0@3(C%!%5%A<8$4
M%B0R0E*1(S-RH4-B8X+_Q``7`0`#`0```````````````````@,!_\0`'!$`
M`P$``P$!``````````````$"$1(A(C%!_]H`#`,!``(1`Q$`/P#9>JS<M]4;
?<J'[:[L(\"$PDJ<>>6$I2/F=>[GNZ[;E!-N[60B/"@``
=&RIUYQ9P$I`R=9&DRY/&2^5O7B!:-46QHKP360H`
M4X&V>OY7',]%N*QD)/0#J?<62T5U@:7?:'W-NF8J#PFV@N7&*BA-O9A3;3GQ
M::`[QSZ#/_7UU!54]HVZ`?F;Z]E*/7NXE?'#>/AWCG./DI`.F-MR9M%G;TF7
MMBZJ/9<2,O[2\P\E00`G/,MP'*0`">OS]-#.W;J+;6J(%;Q!J+.2\4%J+'L>
M=SPH\>`#D^6<?,ZHI2)<FP?$#M'T*>_B;R;N>7JI$VN9*,>[^@LN'Z-G5IMG
,M&6E%.;K.+.UG*4*
M6&Q:PB7HG-[EC\S9\NAZCU"=3YMY!L;6165G$.G:FK>4A$860*TJRL<F,^>2
MGI\,>FB;>+.U)SS-)NJ?7"19\K,%AY24/+)PGE1GJO*CY8QUQ@ZURF"IH:%-
M:5]Q7,V%9+9EQ7DA;;K2PI*@?(@CH=3-9#BOWO9UW@B1'<>F[!GN_BXO4B&2
M?[S0]`"?$CT].F,:RJI\6SKH\^$\AZ.^V'&UI.0I)&01J53A6:TSIVM+63N?
M=^VN%$!:C'EK^WVR4'JMI"@&VO\`[7@?/E]^J#M?U4:E[.J*R*A"6V)\8'E&
M`5>+)_G4^B/MOM=[NFO^(UHC14`^7(&7'?\`3G='Z:^^VNR\_P`$'6V&7'5>
IT8YY4))./%[M42\LFWZ0E8(V^=[;X5PS).VON#-]IED+#'?_`&560`H`
B]>;EQGUYL:8/8R:X7V5=6^SZUL[YJXRWYD@M+24H4YR9"@``
MSRDX6D>7KIH;KV]44O`3=,>DIXL$O[9EE;<9D(YUF*KT'KG2S[(F^MK1Z^CV
M.G;=U%W&XTXA^<J"A$=:0HKP7.?F\@/T^>A+&8WJ$3<G9JJWB''L6E.;M<O@
M*0,H473_`%5<^".F/AYYQC3KXFMV;?$SL]-W94JT0Y!3-*CDE\.,=YGX\V=*
MZSVM,F;-XC7\6`\BSI]TM2HSH9/><A6XD\IQU&2D_0:9''K=<1[?G"#>ICRG
MXD%QB?/:C-%QUCQ,O%M2?1?*1X3@]1I?P9_31^]:&+N7;4NHE,(>#K9Y$J'Z
ML$8^O4?70)V.MP2XD:]X:6CRG']NO@P5+/5<-P<S?\=1\BG1?PXWK4[\V^J\
MI6+!B,E]3!3-8[ESF2`2>7)Z>(=<Z6VV1[$[9266`$(LJI]#P'J0X'4?PAQ"
M?II[6H6'CPY4`]B]KK>,)\\IL1&DHS^PL.-Y^K@:3\U:)^T7:W55L".NAM7:
MJ9*MH<02FD!2D)=<Y2<'H?/RU3=K&KD[5WSMGBM"0H165"NM5(']M"E`M.G_
M`!6`?GRZ\[0MJU9<(JR[ALO2647,"2XB,@N*`0Z%+``\\8/^M9+\A2](7.[N
M*6_F.!0+-TXK<L+<TNL>GL-(0J0Q%:4ZM13CE'@(S@?I^>K#B'Q8O*[=E]#@
5VBXS$W9L>QJPA*0(\DI0X5)./,H*
MAC0E6;7WAN-FI@5D7V8[<3[VY2)\<J2W'?;1'PM/HI2"O'T.JB3MJWWALV1+
M173$V%=15`0%M*23RN+9<3U'7P$9&LUFX@LLMS[_`+OM$2-H5>\)T:JAQ7)$
$A+1""@``
M6RP'7$`X/BSX4J\TYR,:X5EMN]CA!2[GK=_MUZMR[BC15QHT=&*H*5(2OF4I
M2E.%00A1*SS'&23YZ$JO?,.OXZS]]I1%;I9Y>JGL.!3R$]P$%\H'B"<@'.,8
MSJV@4M0[PDH]C-;=G)MT;J@JO7.Z6IB4%_:0AQ"P<*3W93U&!@@Z--S#2W`C
M<%IN7AI!LKAYJ3-2\_'<E--A"9/=.J0'0!T\02#TZ:#-N'VUVRVW6,+1753Z
MWL?I/>!I/\I;2?KJQX1WJ-L\`(3UE^$=J$OPL.(Y"5-.+2%8/GT'-GW:[]CJ
5AE3_`+P<3K)E3;E\^&Z]*QU1#:\*
M//\`=Y_()/KIJ?0LKMCVW90UNYMNS:*WCID0IK*FG4*'F",:RI3V=_P%W;]T
M-VAV5MB2YBJM%?D6CT;6?)+B1TR<!0&/<=:_U4[KVW2;IIGZ>_K8]A!?3A;3
"R`H`
('S'N/QU*:PH`
MU.@A3V<"UAB5726WVB`3R^:<^\>8UQE7<%DI:5S*4ZRIQ">4@J`!)'4=/(Z5
MUSP`WKLZ6J9PHW;S0DDJ146KBR&Q^UMY!"T#TZ$''F3J`J^[0%4YW5APT59.
M(&._1(CNH/\`B`&U8^:E'XZLK3(N&@GAT?#^ZER4L;;CPY,5MU*W4,C.'4EI
M0Z#)_/Y?`'1A*GU&T=NQFI\Q+3$.,AM'.05K2A(3G'KY>?EI4-VO:"N%J9K>
/'*:E:_\`F>E,M-'/[N4*
M<^J5I.K7;O9WW%N:<BRXN;J5/8"@OV/7J4AA1_\`5PGG<^9.>@\1'31S2!0V
M"S:;SM#[O36UR'8>Q8+OXZ:.B9(!_L-']6<>)0Z>@Z>>LZ:NB5-7&K8#*&(T
J9M+;3:1@)2!@#7Q04U70U3%73P6(4-A`0VRR@)2D#W`:GZC5:6F</__9
EOF
    $self->_write_data_to_file($data, $path);
}

sub _manifest_skip {
    my $self = shift;
    return <<'EOF';
^\.git\/
maint
^tags$
.last_cover_stats
Makefile$
^blib
^pm_to_blib
^.*.bak
^.*.old
^t.*sessions
^cover_db
^.*\.log
^.*\.swp$
EOF
}

sub _jquery_minified {
    my $self = shift;
    return <<'EOF';
/*!
 * jQuery JavaScript Library v1.4.2
 * http://jquery.com/
 *
 * Copyright 2010, John Resig
 * Dual licensed under the MIT or GPL Version 2 licenses.
 * http://jquery.org/license
 *
 * Includes Sizzle.js
 * http://sizzlejs.com/
 * Copyright 2010, The Dojo Foundation
 * Released under the MIT, BSD, and GPL Licenses.
 *
 * Date: Sat Feb 13 22:33:48 2010 -0500
 */
(function(A,w){function ma(){if(!c.isReady){try{s.documentElement.doScroll("left")}catch(a){setTimeout(ma,1);return}c.ready()}}function Qa(a,b){b.src?c.ajax({url:b.src,async:false,dataType:"script"}):c.globalEval(b.text||b.textContent||b.innerHTML||"");b.parentNode&&b.parentNode.removeChild(b)}function X(a,b,d,f,e,j){var i=a.length;if(typeof b==="object"){for(var o in b)X(a,o,b[o],f,e,d);return a}if(d!==w){f=!j&&f&&c.isFunction(d);for(o=0;o<i;o++)e(a[o],b,f?d.call(a[o],o,e(a[o],b)):d,j);return a}return i?
e(a[0],b):w}function J(){return(new Date).getTime()}function Y(){return false}function Z(){return true}function na(a,b,d){d[0].type=a;return c.event.handle.apply(b,d)}function oa(a){var b,d=[],f=[],e=arguments,j,i,o,k,n,r;i=c.data(this,"events");if(!(a.liveFired===this||!i||!i.live||a.button&&a.type==="click")){a.liveFired=this;var u=i.live.slice(0);for(k=0;k<u.length;k++){i=u[k];i.origType.replace(O,"")===a.type?f.push(i.selector):u.splice(k--,1)}j=c(a.target).closest(f,a.currentTarget);n=0;for(r=
j.length;n<r;n++)for(k=0;k<u.length;k++){i=u[k];if(j[n].selector===i.selector){o=j[n].elem;f=null;if(i.preType==="mouseenter"||i.preType==="mouseleave")f=c(a.relatedTarget).closest(i.selector)[0];if(!f||f!==o)d.push({elem:o,handleObj:i})}}n=0;for(r=d.length;n<r;n++){j=d[n];a.currentTarget=j.elem;a.data=j.handleObj.data;a.handleObj=j.handleObj;if(j.handleObj.origHandler.apply(j.elem,e)===false){b=false;break}}return b}}function pa(a,b){return"live."+(a&&a!=="*"?a+".":"")+b.replace(/\./g,"`").replace(/ /g,
"&")}function qa(a){return!a||!a.parentNode||a.parentNode.nodeType===11}function ra(a,b){var d=0;b.each(function(){if(this.nodeName===(a[d]&&a[d].nodeName)){var f=c.data(a[d++]),e=c.data(this,f);if(f=f&&f.events){delete e.handle;e.events={};for(var j in f)for(var i in f[j])c.event.add(this,j,f[j][i],f[j][i].data)}}})}function sa(a,b,d){var f,e,j;b=b&&b[0]?b[0].ownerDocument||b[0]:s;if(a.length===1&&typeof a[0]==="string"&&a[0].length<512&&b===s&&!ta.test(a[0])&&(c.support.checkClone||!ua.test(a[0]))){e=
true;if(j=c.fragments[a[0]])if(j!==1)f=j}if(!f){f=b.createDocumentFragment();c.clean(a,b,f,d)}if(e)c.fragments[a[0]]=j?f:1;return{fragment:f,cacheable:e}}function K(a,b){var d={};c.each(va.concat.apply([],va.slice(0,b)),function(){d[this]=a});return d}function wa(a){return"scrollTo"in a&&a.document?a:a.nodeType===9?a.defaultView||a.parentWindow:false}var c=function(a,b){return new c.fn.init(a,b)},Ra=A.jQuery,Sa=A.$,s=A.document,T,Ta=/^[^<]*(<[\w\W]+>)[^>]*$|^#([\w-]+)$/,Ua=/^.[^:#\[\.,]*$/,Va=/\S/,
Wa=/^(\s|\u00A0)+|(\s|\u00A0)+$/g,Xa=/^<(\w+)\s*\/?>(?:<\/\1>)?$/,P=navigator.userAgent,xa=false,Q=[],L,$=Object.prototype.toString,aa=Object.prototype.hasOwnProperty,ba=Array.prototype.push,R=Array.prototype.slice,ya=Array.prototype.indexOf;c.fn=c.prototype={init:function(a,b){var d,f;if(!a)return this;if(a.nodeType){this.context=this[0]=a;this.length=1;return this}if(a==="body"&&!b){this.context=s;this[0]=s.body;this.selector="body";this.length=1;return this}if(typeof a==="string")if((d=Ta.exec(a))&&
(d[1]||!b))if(d[1]){f=b?b.ownerDocument||b:s;if(a=Xa.exec(a))if(c.isPlainObject(b)){a=[s.createElement(a[1])];c.fn.attr.call(a,b,true)}else a=[f.createElement(a[1])];else{a=sa([d[1]],[f]);a=(a.cacheable?a.fragment.cloneNode(true):a.fragment).childNodes}return c.merge(this,a)}else{if(b=s.getElementById(d[2])){if(b.id!==d[2])return T.find(a);this.length=1;this[0]=b}this.context=s;this.selector=a;return this}else if(!b&&/^\w+$/.test(a)){this.selector=a;this.context=s;a=s.getElementsByTagName(a);return c.merge(this,
a)}else return!b||b.jquery?(b||T).find(a):c(b).find(a);else if(c.isFunction(a))return T.ready(a);if(a.selector!==w){this.selector=a.selector;this.context=a.context}return c.makeArray(a,this)},selector:"",jquery:"1.4.2",length:0,size:function(){return this.length},toArray:function(){return R.call(this,0)},get:function(a){return a==null?this.toArray():a<0?this.slice(a)[0]:this[a]},pushStack:function(a,b,d){var f=c();c.isArray(a)?ba.apply(f,a):c.merge(f,a);f.prevObject=this;f.context=this.context;if(b===
"find")f.selector=this.selector+(this.selector?" ":"")+d;else if(b)f.selector=this.selector+"."+b+"("+d+")";return f},each:function(a,b){return c.each(this,a,b)},ready:function(a){c.bindReady();if(c.isReady)a.call(s,c);else Q&&Q.push(a);return this},eq:function(a){return a===-1?this.slice(a):this.slice(a,+a+1)},first:function(){return this.eq(0)},last:function(){return this.eq(-1)},slice:function(){return this.pushStack(R.apply(this,arguments),"slice",R.call(arguments).join(","))},map:function(a){return this.pushStack(c.map(this,
function(b,d){return a.call(b,d,b)}))},end:function(){return this.prevObject||c(null)},push:ba,sort:[].sort,splice:[].splice};c.fn.init.prototype=c.fn;c.extend=c.fn.extend=function(){var a=arguments[0]||{},b=1,d=arguments.length,f=false,e,j,i,o;if(typeof a==="boolean"){f=a;a=arguments[1]||{};b=2}if(typeof a!=="object"&&!c.isFunction(a))a={};if(d===b){a=this;--b}for(;b<d;b++)if((e=arguments[b])!=null)for(j in e){i=a[j];o=e[j];if(a!==o)if(f&&o&&(c.isPlainObject(o)||c.isArray(o))){i=i&&(c.isPlainObject(i)||
c.isArray(i))?i:c.isArray(o)?[]:{};a[j]=c.extend(f,i,o)}else if(o!==w)a[j]=o}return a};c.extend({noConflict:function(a){A.$=Sa;if(a)A.jQuery=Ra;return c},isReady:false,ready:function(){if(!c.isReady){if(!s.body)return setTimeout(c.ready,13);c.isReady=true;if(Q){for(var a,b=0;a=Q[b++];)a.call(s,c);Q=null}c.fn.triggerHandler&&c(s).triggerHandler("ready")}},bindReady:function(){if(!xa){xa=true;if(s.readyState==="complete")return c.ready();if(s.addEventListener){s.addEventListener("DOMContentLoaded",
L,false);A.addEventListener("load",c.ready,false)}else if(s.attachEvent){s.attachEvent("onreadystatechange",L);A.attachEvent("onload",c.ready);var a=false;try{a=A.frameElement==null}catch(b){}s.documentElement.doScroll&&a&&ma()}}},isFunction:function(a){return $.call(a)==="[object Function]"},isArray:function(a){return $.call(a)==="[object Array]"},isPlainObject:function(a){if(!a||$.call(a)!=="[object Object]"||a.nodeType||a.setInterval)return false;if(a.constructor&&!aa.call(a,"constructor")&&!aa.call(a.constructor.prototype,
"isPrototypeOf"))return false;var b;for(b in a);return b===w||aa.call(a,b)},isEmptyObject:function(a){for(var b in a)return false;return true},error:function(a){throw a;},parseJSON:function(a){if(typeof a!=="string"||!a)return null;a=c.trim(a);if(/^[\],:{}\s]*$/.test(a.replace(/\\(?:["\\\/bfnrt]|u[0-9a-fA-F]{4})/g,"@").replace(/"[^"\\\n\r]*"|true|false|null|-?\d+(?:\.\d*)?(?:[eE][+\-]?\d+)?/g,"]").replace(/(?:^|:|,)(?:\s*\[)+/g,"")))return A.JSON&&A.JSON.parse?A.JSON.parse(a):(new Function("return "+
a))();else c.error("Invalid JSON: "+a)},noop:function(){},globalEval:function(a){if(a&&Va.test(a)){var b=s.getElementsByTagName("head")[0]||s.documentElement,d=s.createElement("script");d.type="text/javascript";if(c.support.scriptEval)d.appendChild(s.createTextNode(a));else d.text=a;b.insertBefore(d,b.firstChild);b.removeChild(d)}},nodeName:function(a,b){return a.nodeName&&a.nodeName.toUpperCase()===b.toUpperCase()},each:function(a,b,d){var f,e=0,j=a.length,i=j===w||c.isFunction(a);if(d)if(i)for(f in a){if(b.apply(a[f],
d)===false)break}else for(;e<j;){if(b.apply(a[e++],d)===false)break}else if(i)for(f in a){if(b.call(a[f],f,a[f])===false)break}else for(d=a[0];e<j&&b.call(d,e,d)!==false;d=a[++e]);return a},trim:function(a){return(a||"").replace(Wa,"")},makeArray:function(a,b){b=b||[];if(a!=null)a.length==null||typeof a==="string"||c.isFunction(a)||typeof a!=="function"&&a.setInterval?ba.call(b,a):c.merge(b,a);return b},inArray:function(a,b){if(b.indexOf)return b.indexOf(a);for(var d=0,f=b.length;d<f;d++)if(b[d]===
a)return d;return-1},merge:function(a,b){var d=a.length,f=0;if(typeof b.length==="number")for(var e=b.length;f<e;f++)a[d++]=b[f];else for(;b[f]!==w;)a[d++]=b[f++];a.length=d;return a},grep:function(a,b,d){for(var f=[],e=0,j=a.length;e<j;e++)!d!==!b(a[e],e)&&f.push(a[e]);return f},map:function(a,b,d){for(var f=[],e,j=0,i=a.length;j<i;j++){e=b(a[j],j,d);if(e!=null)f[f.length]=e}return f.concat.apply([],f)},guid:1,proxy:function(a,b,d){if(arguments.length===2)if(typeof b==="string"){d=a;a=d[b];b=w}else if(b&&
!c.isFunction(b)){d=b;b=w}if(!b&&a)b=function(){return a.apply(d||this,arguments)};if(a)b.guid=a.guid=a.guid||b.guid||c.guid++;return b},uaMatch:function(a){a=a.toLowerCase();a=/(webkit)[ \/]([\w.]+)/.exec(a)||/(opera)(?:.*version)?[ \/]([\w.]+)/.exec(a)||/(msie) ([\w.]+)/.exec(a)||!/compatible/.test(a)&&/(mozilla)(?:.*? rv:([\w.]+))?/.exec(a)||[];return{browser:a[1]||"",version:a[2]||"0"}},browser:{}});P=c.uaMatch(P);if(P.browser){c.browser[P.browser]=true;c.browser.version=P.version}if(c.browser.webkit)c.browser.safari=
true;if(ya)c.inArray=function(a,b){return ya.call(b,a)};T=c(s);if(s.addEventListener)L=function(){s.removeEventListener("DOMContentLoaded",L,false);c.ready()};else if(s.attachEvent)L=function(){if(s.readyState==="complete"){s.detachEvent("onreadystatechange",L);c.ready()}};(function(){c.support={};var a=s.documentElement,b=s.createElement("script"),d=s.createElement("div"),f="script"+J();d.style.display="none";d.innerHTML="   <link/><table></table><a href='/a' style='color:red;float:left;opacity:.55;'>a</a><input type='checkbox'/>";
var e=d.getElementsByTagName("*"),j=d.getElementsByTagName("a")[0];if(!(!e||!e.length||!j)){c.support={leadingWhitespace:d.firstChild.nodeType===3,tbody:!d.getElementsByTagName("tbody").length,htmlSerialize:!!d.getElementsByTagName("link").length,style:/red/.test(j.getAttribute("style")),hrefNormalized:j.getAttribute("href")==="/a",opacity:/^0.55$/.test(j.style.opacity),cssFloat:!!j.style.cssFloat,checkOn:d.getElementsByTagName("input")[0].value==="on",optSelected:s.createElement("select").appendChild(s.createElement("option")).selected,
parentNode:d.removeChild(d.appendChild(s.createElement("div"))).parentNode===null,deleteExpando:true,checkClone:false,scriptEval:false,noCloneEvent:true,boxModel:null};b.type="text/javascript";try{b.appendChild(s.createTextNode("window."+f+"=1;"))}catch(i){}a.insertBefore(b,a.firstChild);if(A[f]){c.support.scriptEval=true;delete A[f]}try{delete b.test}catch(o){c.support.deleteExpando=false}a.removeChild(b);if(d.attachEvent&&d.fireEvent){d.attachEvent("onclick",function k(){c.support.noCloneEvent=
false;d.detachEvent("onclick",k)});d.cloneNode(true).fireEvent("onclick")}d=s.createElement("div");d.innerHTML="<input type='radio' name='radiotest' checked='checked'/>";a=s.createDocumentFragment();a.appendChild(d.firstChild);c.support.checkClone=a.cloneNode(true).cloneNode(true).lastChild.checked;c(function(){var k=s.createElement("div");k.style.width=k.style.paddingLeft="1px";s.body.appendChild(k);c.boxModel=c.support.boxModel=k.offsetWidth===2;s.body.removeChild(k).style.display="none"});a=function(k){var n=
s.createElement("div");k="on"+k;var r=k in n;if(!r){n.setAttribute(k,"return;");r=typeof n[k]==="function"}return r};c.support.submitBubbles=a("submit");c.support.changeBubbles=a("change");a=b=d=e=j=null}})();c.props={"for":"htmlFor","class":"className",readonly:"readOnly",maxlength:"maxLength",cellspacing:"cellSpacing",rowspan:"rowSpan",colspan:"colSpan",tabindex:"tabIndex",usemap:"useMap",frameborder:"frameBorder"};var G="jQuery"+J(),Ya=0,za={};c.extend({cache:{},expando:G,noData:{embed:true,object:true,
applet:true},data:function(a,b,d){if(!(a.nodeName&&c.noData[a.nodeName.toLowerCase()])){a=a==A?za:a;var f=a[G],e=c.cache;if(!f&&typeof b==="string"&&d===w)return null;f||(f=++Ya);if(typeof b==="object"){a[G]=f;e[f]=c.extend(true,{},b)}else if(!e[f]){a[G]=f;e[f]={}}a=e[f];if(d!==w)a[b]=d;return typeof b==="string"?a[b]:a}},removeData:function(a,b){if(!(a.nodeName&&c.noData[a.nodeName.toLowerCase()])){a=a==A?za:a;var d=a[G],f=c.cache,e=f[d];if(b){if(e){delete e[b];c.isEmptyObject(e)&&c.removeData(a)}}else{if(c.support.deleteExpando)delete a[c.expando];
else a.removeAttribute&&a.removeAttribute(c.expando);delete f[d]}}}});c.fn.extend({data:function(a,b){if(typeof a==="undefined"&&this.length)return c.data(this[0]);else if(typeof a==="object")return this.each(function(){c.data(this,a)});var d=a.split(".");d[1]=d[1]?"."+d[1]:"";if(b===w){var f=this.triggerHandler("getData"+d[1]+"!",[d[0]]);if(f===w&&this.length)f=c.data(this[0],a);return f===w&&d[1]?this.data(d[0]):f}else return this.trigger("setData"+d[1]+"!",[d[0],b]).each(function(){c.data(this,
a,b)})},removeData:function(a){return this.each(function(){c.removeData(this,a)})}});c.extend({queue:function(a,b,d){if(a){b=(b||"fx")+"queue";var f=c.data(a,b);if(!d)return f||[];if(!f||c.isArray(d))f=c.data(a,b,c.makeArray(d));else f.push(d);return f}},dequeue:function(a,b){b=b||"fx";var d=c.queue(a,b),f=d.shift();if(f==="inprogress")f=d.shift();if(f){b==="fx"&&d.unshift("inprogress");f.call(a,function(){c.dequeue(a,b)})}}});c.fn.extend({queue:function(a,b){if(typeof a!=="string"){b=a;a="fx"}if(b===
w)return c.queue(this[0],a);return this.each(function(){var d=c.queue(this,a,b);a==="fx"&&d[0]!=="inprogress"&&c.dequeue(this,a)})},dequeue:function(a){return this.each(function(){c.dequeue(this,a)})},delay:function(a,b){a=c.fx?c.fx.speeds[a]||a:a;b=b||"fx";return this.queue(b,function(){var d=this;setTimeout(function(){c.dequeue(d,b)},a)})},clearQueue:function(a){return this.queue(a||"fx",[])}});var Aa=/[\n\t]/g,ca=/\s+/,Za=/\r/g,$a=/href|src|style/,ab=/(button|input)/i,bb=/(button|input|object|select|textarea)/i,
cb=/^(a|area)$/i,Ba=/radio|checkbox/;c.fn.extend({attr:function(a,b){return X(this,a,b,true,c.attr)},removeAttr:function(a){return this.each(function(){c.attr(this,a,"");this.nodeType===1&&this.removeAttribute(a)})},addClass:function(a){if(c.isFunction(a))return this.each(function(n){var r=c(this);r.addClass(a.call(this,n,r.attr("class")))});if(a&&typeof a==="string")for(var b=(a||"").split(ca),d=0,f=this.length;d<f;d++){var e=this[d];if(e.nodeType===1)if(e.className){for(var j=" "+e.className+" ",
i=e.className,o=0,k=b.length;o<k;o++)if(j.indexOf(" "+b[o]+" ")<0)i+=" "+b[o];e.className=c.trim(i)}else e.className=a}return this},removeClass:function(a){if(c.isFunction(a))return this.each(function(k){var n=c(this);n.removeClass(a.call(this,k,n.attr("class")))});if(a&&typeof a==="string"||a===w)for(var b=(a||"").split(ca),d=0,f=this.length;d<f;d++){var e=this[d];if(e.nodeType===1&&e.className)if(a){for(var j=(" "+e.className+" ").replace(Aa," "),i=0,o=b.length;i<o;i++)j=j.replace(" "+b[i]+" ",
" ");e.className=c.trim(j)}else e.className=""}return this},toggleClass:function(a,b){var d=typeof a,f=typeof b==="boolean";if(c.isFunction(a))return this.each(function(e){var j=c(this);j.toggleClass(a.call(this,e,j.attr("class"),b),b)});return this.each(function(){if(d==="string")for(var e,j=0,i=c(this),o=b,k=a.split(ca);e=k[j++];){o=f?o:!i.hasClass(e);i[o?"addClass":"removeClass"](e)}else if(d==="undefined"||d==="boolean"){this.className&&c.data(this,"__className__",this.className);this.className=
this.className||a===false?"":c.data(this,"__className__")||""}})},hasClass:function(a){a=" "+a+" ";for(var b=0,d=this.length;b<d;b++)if((" "+this[b].className+" ").replace(Aa," ").indexOf(a)>-1)return true;return false},val:function(a){if(a===w){var b=this[0];if(b){if(c.nodeName(b,"option"))return(b.attributes.value||{}).specified?b.value:b.text;if(c.nodeName(b,"select")){var d=b.selectedIndex,f=[],e=b.options;b=b.type==="select-one";if(d<0)return null;var j=b?d:0;for(d=b?d+1:e.length;j<d;j++){var i=
e[j];if(i.selected){a=c(i).val();if(b)return a;f.push(a)}}return f}if(Ba.test(b.type)&&!c.support.checkOn)return b.getAttribute("value")===null?"on":b.value;return(b.value||"").replace(Za,"")}return w}var o=c.isFunction(a);return this.each(function(k){var n=c(this),r=a;if(this.nodeType===1){if(o)r=a.call(this,k,n.val());if(typeof r==="number")r+="";if(c.isArray(r)&&Ba.test(this.type))this.checked=c.inArray(n.val(),r)>=0;else if(c.nodeName(this,"select")){var u=c.makeArray(r);c("option",this).each(function(){this.selected=
c.inArray(c(this).val(),u)>=0});if(!u.length)this.selectedIndex=-1}else this.value=r}})}});c.extend({attrFn:{val:true,css:true,html:true,text:true,data:true,width:true,height:true,offset:true},attr:function(a,b,d,f){if(!a||a.nodeType===3||a.nodeType===8)return w;if(f&&b in c.attrFn)return c(a)[b](d);f=a.nodeType!==1||!c.isXMLDoc(a);var e=d!==w;b=f&&c.props[b]||b;if(a.nodeType===1){var j=$a.test(b);if(b in a&&f&&!j){if(e){b==="type"&&ab.test(a.nodeName)&&a.parentNode&&c.error("type property can't be changed");
a[b]=d}if(c.nodeName(a,"form")&&a.getAttributeNode(b))return a.getAttributeNode(b).nodeValue;if(b==="tabIndex")return(b=a.getAttributeNode("tabIndex"))&&b.specified?b.value:bb.test(a.nodeName)||cb.test(a.nodeName)&&a.href?0:w;return a[b]}if(!c.support.style&&f&&b==="style"){if(e)a.style.cssText=""+d;return a.style.cssText}e&&a.setAttribute(b,""+d);a=!c.support.hrefNormalized&&f&&j?a.getAttribute(b,2):a.getAttribute(b);return a===null?w:a}return c.style(a,b,d)}});var O=/\.(.*)$/,db=function(a){return a.replace(/[^\w\s\.\|`]/g,
function(b){return"\\"+b})};c.event={add:function(a,b,d,f){if(!(a.nodeType===3||a.nodeType===8)){if(a.setInterval&&a!==A&&!a.frameElement)a=A;var e,j;if(d.handler){e=d;d=e.handler}if(!d.guid)d.guid=c.guid++;if(j=c.data(a)){var i=j.events=j.events||{},o=j.handle;if(!o)j.handle=o=function(){return typeof c!=="undefined"&&!c.event.triggered?c.event.handle.apply(o.elem,arguments):w};o.elem=a;b=b.split(" ");for(var k,n=0,r;k=b[n++];){j=e?c.extend({},e):{handler:d,data:f};if(k.indexOf(".")>-1){r=k.split(".");
k=r.shift();j.namespace=r.slice(0).sort().join(".")}else{r=[];j.namespace=""}j.type=k;j.guid=d.guid;var u=i[k],z=c.event.special[k]||{};if(!u){u=i[k]=[];if(!z.setup||z.setup.call(a,f,r,o)===false)if(a.addEventListener)a.addEventListener(k,o,false);else a.attachEvent&&a.attachEvent("on"+k,o)}if(z.add){z.add.call(a,j);if(!j.handler.guid)j.handler.guid=d.guid}u.push(j);c.event.global[k]=true}a=null}}},global:{},remove:function(a,b,d,f){if(!(a.nodeType===3||a.nodeType===8)){var e,j=0,i,o,k,n,r,u,z=c.data(a),
C=z&&z.events;if(z&&C){if(b&&b.type){d=b.handler;b=b.type}if(!b||typeof b==="string"&&b.charAt(0)==="."){b=b||"";for(e in C)c.event.remove(a,e+b)}else{for(b=b.split(" ");e=b[j++];){n=e;i=e.indexOf(".")<0;o=[];if(!i){o=e.split(".");e=o.shift();k=new RegExp("(^|\\.)"+c.map(o.slice(0).sort(),db).join("\\.(?:.*\\.)?")+"(\\.|$)")}if(r=C[e])if(d){n=c.event.special[e]||{};for(B=f||0;B<r.length;B++){u=r[B];if(d.guid===u.guid){if(i||k.test(u.namespace)){f==null&&r.splice(B--,1);n.remove&&n.remove.call(a,u)}if(f!=
null)break}}if(r.length===0||f!=null&&r.length===1){if(!n.teardown||n.teardown.call(a,o)===false)Ca(a,e,z.handle);delete C[e]}}else for(var B=0;B<r.length;B++){u=r[B];if(i||k.test(u.namespace)){c.event.remove(a,n,u.handler,B);r.splice(B--,1)}}}if(c.isEmptyObject(C)){if(b=z.handle)b.elem=null;delete z.events;delete z.handle;c.isEmptyObject(z)&&c.removeData(a)}}}}},trigger:function(a,b,d,f){var e=a.type||a;if(!f){a=typeof a==="object"?a[G]?a:c.extend(c.Event(e),a):c.Event(e);if(e.indexOf("!")>=0){a.type=
e=e.slice(0,-1);a.exclusive=true}if(!d){a.stopPropagation();c.event.global[e]&&c.each(c.cache,function(){this.events&&this.events[e]&&c.event.trigger(a,b,this.handle.elem)})}if(!d||d.nodeType===3||d.nodeType===8)return w;a.result=w;a.target=d;b=c.makeArray(b);b.unshift(a)}a.currentTarget=d;(f=c.data(d,"handle"))&&f.apply(d,b);f=d.parentNode||d.ownerDocument;try{if(!(d&&d.nodeName&&c.noData[d.nodeName.toLowerCase()]))if(d["on"+e]&&d["on"+e].apply(d,b)===false)a.result=false}catch(j){}if(!a.isPropagationStopped()&&
f)c.event.trigger(a,b,f,true);else if(!a.isDefaultPrevented()){f=a.target;var i,o=c.nodeName(f,"a")&&e==="click",k=c.event.special[e]||{};if((!k._default||k._default.call(d,a)===false)&&!o&&!(f&&f.nodeName&&c.noData[f.nodeName.toLowerCase()])){try{if(f[e]){if(i=f["on"+e])f["on"+e]=null;c.event.triggered=true;f[e]()}}catch(n){}if(i)f["on"+e]=i;c.event.triggered=false}}},handle:function(a){var b,d,f,e;a=arguments[0]=c.event.fix(a||A.event);a.currentTarget=this;b=a.type.indexOf(".")<0&&!a.exclusive;
if(!b){d=a.type.split(".");a.type=d.shift();f=new RegExp("(^|\\.)"+d.slice(0).sort().join("\\.(?:.*\\.)?")+"(\\.|$)")}e=c.data(this,"events");d=e[a.type];if(e&&d){d=d.slice(0);e=0;for(var j=d.length;e<j;e++){var i=d[e];if(b||f.test(i.namespace)){a.handler=i.handler;a.data=i.data;a.handleObj=i;i=i.handler.apply(this,arguments);if(i!==w){a.result=i;if(i===false){a.preventDefault();a.stopPropagation()}}if(a.isImmediatePropagationStopped())break}}}return a.result},props:"altKey attrChange attrName bubbles button cancelable charCode clientX clientY ctrlKey currentTarget data detail eventPhase fromElement handler keyCode layerX layerY metaKey newValue offsetX offsetY originalTarget pageX pageY prevValue relatedNode relatedTarget screenX screenY shiftKey srcElement target toElement view wheelDelta which".split(" "),
fix:function(a){if(a[G])return a;var b=a;a=c.Event(b);for(var d=this.props.length,f;d;){f=this.props[--d];a[f]=b[f]}if(!a.target)a.target=a.srcElement||s;if(a.target.nodeType===3)a.target=a.target.parentNode;if(!a.relatedTarget&&a.fromElement)a.relatedTarget=a.fromElement===a.target?a.toElement:a.fromElement;if(a.pageX==null&&a.clientX!=null){b=s.documentElement;d=s.body;a.pageX=a.clientX+(b&&b.scrollLeft||d&&d.scrollLeft||0)-(b&&b.clientLeft||d&&d.clientLeft||0);a.pageY=a.clientY+(b&&b.scrollTop||
d&&d.scrollTop||0)-(b&&b.clientTop||d&&d.clientTop||0)}if(!a.which&&(a.charCode||a.charCode===0?a.charCode:a.keyCode))a.which=a.charCode||a.keyCode;if(!a.metaKey&&a.ctrlKey)a.metaKey=a.ctrlKey;if(!a.which&&a.button!==w)a.which=a.button&1?1:a.button&2?3:a.button&4?2:0;return a},guid:1E8,proxy:c.proxy,special:{ready:{setup:c.bindReady,teardown:c.noop},live:{add:function(a){c.event.add(this,a.origType,c.extend({},a,{handler:oa}))},remove:function(a){var b=true,d=a.origType.replace(O,"");c.each(c.data(this,
"events").live||[],function(){if(d===this.origType.replace(O,""))return b=false});b&&c.event.remove(this,a.origType,oa)}},beforeunload:{setup:function(a,b,d){if(this.setInterval)this.onbeforeunload=d;return false},teardown:function(a,b){if(this.onbeforeunload===b)this.onbeforeunload=null}}}};var Ca=s.removeEventListener?function(a,b,d){a.removeEventListener(b,d,false)}:function(a,b,d){a.detachEvent("on"+b,d)};c.Event=function(a){if(!this.preventDefault)return new c.Event(a);if(a&&a.type){this.originalEvent=
a;this.type=a.type}else this.type=a;this.timeStamp=J();this[G]=true};c.Event.prototype={preventDefault:function(){this.isDefaultPrevented=Z;var a=this.originalEvent;if(a){a.preventDefault&&a.preventDefault();a.returnValue=false}},stopPropagation:function(){this.isPropagationStopped=Z;var a=this.originalEvent;if(a){a.stopPropagation&&a.stopPropagation();a.cancelBubble=true}},stopImmediatePropagation:function(){this.isImmediatePropagationStopped=Z;this.stopPropagation()},isDefaultPrevented:Y,isPropagationStopped:Y,
isImmediatePropagationStopped:Y};var Da=function(a){var b=a.relatedTarget;try{for(;b&&b!==this;)b=b.parentNode;if(b!==this){a.type=a.data;c.event.handle.apply(this,arguments)}}catch(d){}},Ea=function(a){a.type=a.data;c.event.handle.apply(this,arguments)};c.each({mouseenter:"mouseover",mouseleave:"mouseout"},function(a,b){c.event.special[a]={setup:function(d){c.event.add(this,b,d&&d.selector?Ea:Da,a)},teardown:function(d){c.event.remove(this,b,d&&d.selector?Ea:Da)}}});if(!c.support.submitBubbles)c.event.special.submit=
{setup:function(){if(this.nodeName.toLowerCase()!=="form"){c.event.add(this,"click.specialSubmit",function(a){var b=a.target,d=b.type;if((d==="submit"||d==="image")&&c(b).closest("form").length)return na("submit",this,arguments)});c.event.add(this,"keypress.specialSubmit",function(a){var b=a.target,d=b.type;if((d==="text"||d==="password")&&c(b).closest("form").length&&a.keyCode===13)return na("submit",this,arguments)})}else return false},teardown:function(){c.event.remove(this,".specialSubmit")}};
if(!c.support.changeBubbles){var da=/textarea|input|select/i,ea,Fa=function(a){var b=a.type,d=a.value;if(b==="radio"||b==="checkbox")d=a.checked;else if(b==="select-multiple")d=a.selectedIndex>-1?c.map(a.options,function(f){return f.selected}).join("-"):"";else if(a.nodeName.toLowerCase()==="select")d=a.selectedIndex;return d},fa=function(a,b){var d=a.target,f,e;if(!(!da.test(d.nodeName)||d.readOnly)){f=c.data(d,"_change_data");e=Fa(d);if(a.type!=="focusout"||d.type!=="radio")c.data(d,"_change_data",
e);if(!(f===w||e===f))if(f!=null||e){a.type="change";return c.event.trigger(a,b,d)}}};c.event.special.change={filters:{focusout:fa,click:function(a){var b=a.target,d=b.type;if(d==="radio"||d==="checkbox"||b.nodeName.toLowerCase()==="select")return fa.call(this,a)},keydown:function(a){var b=a.target,d=b.type;if(a.keyCode===13&&b.nodeName.toLowerCase()!=="textarea"||a.keyCode===32&&(d==="checkbox"||d==="radio")||d==="select-multiple")return fa.call(this,a)},beforeactivate:function(a){a=a.target;c.data(a,
"_change_data",Fa(a))}},setup:function(){if(this.type==="file")return false;for(var a in ea)c.event.add(this,a+".specialChange",ea[a]);return da.test(this.nodeName)},teardown:function(){c.event.remove(this,".specialChange");return da.test(this.nodeName)}};ea=c.event.special.change.filters}s.addEventListener&&c.each({focus:"focusin",blur:"focusout"},function(a,b){function d(f){f=c.event.fix(f);f.type=b;return c.event.handle.call(this,f)}c.event.special[b]={setup:function(){this.addEventListener(a,
d,true)},teardown:function(){this.removeEventListener(a,d,true)}}});c.each(["bind","one"],function(a,b){c.fn[b]=function(d,f,e){if(typeof d==="object"){for(var j in d)this[b](j,f,d[j],e);return this}if(c.isFunction(f)){e=f;f=w}var i=b==="one"?c.proxy(e,function(k){c(this).unbind(k,i);return e.apply(this,arguments)}):e;if(d==="unload"&&b!=="one")this.one(d,f,e);else{j=0;for(var o=this.length;j<o;j++)c.event.add(this[j],d,i,f)}return this}});c.fn.extend({unbind:function(a,b){if(typeof a==="object"&&
!a.preventDefault)for(var d in a)this.unbind(d,a[d]);else{d=0;for(var f=this.length;d<f;d++)c.event.remove(this[d],a,b)}return this},delegate:function(a,b,d,f){return this.live(b,d,f,a)},undelegate:function(a,b,d){return arguments.length===0?this.unbind("live"):this.die(b,null,d,a)},trigger:function(a,b){return this.each(function(){c.event.trigger(a,b,this)})},triggerHandler:function(a,b){if(this[0]){a=c.Event(a);a.preventDefault();a.stopPropagation();c.event.trigger(a,b,this[0]);return a.result}},
toggle:function(a){for(var b=arguments,d=1;d<b.length;)c.proxy(a,b[d++]);return this.click(c.proxy(a,function(f){var e=(c.data(this,"lastToggle"+a.guid)||0)%d;c.data(this,"lastToggle"+a.guid,e+1);f.preventDefault();return b[e].apply(this,arguments)||false}))},hover:function(a,b){return this.mouseenter(a).mouseleave(b||a)}});var Ga={focus:"focusin",blur:"focusout",mouseenter:"mouseover",mouseleave:"mouseout"};c.each(["live","die"],function(a,b){c.fn[b]=function(d,f,e,j){var i,o=0,k,n,r=j||this.selector,
u=j?this:c(this.context);if(c.isFunction(f)){e=f;f=w}for(d=(d||"").split(" ");(i=d[o++])!=null;){j=O.exec(i);k="";if(j){k=j[0];i=i.replace(O,"")}if(i==="hover")d.push("mouseenter"+k,"mouseleave"+k);else{n=i;if(i==="focus"||i==="blur"){d.push(Ga[i]+k);i+=k}else i=(Ga[i]||i)+k;b==="live"?u.each(function(){c.event.add(this,pa(i,r),{data:f,selector:r,handler:e,origType:i,origHandler:e,preType:n})}):u.unbind(pa(i,r),e)}}return this}});c.each("blur focus focusin focusout load resize scroll unload click dblclick mousedown mouseup mousemove mouseover mouseout mouseenter mouseleave change select submit keydown keypress keyup error".split(" "),
function(a,b){c.fn[b]=function(d){return d?this.bind(b,d):this.trigger(b)};if(c.attrFn)c.attrFn[b]=true});A.attachEvent&&!A.addEventListener&&A.attachEvent("onunload",function(){for(var a in c.cache)if(c.cache[a].handle)try{c.event.remove(c.cache[a].handle.elem)}catch(b){}});(function(){function a(g){for(var h="",l,m=0;g[m];m++){l=g[m];if(l.nodeType===3||l.nodeType===4)h+=l.nodeValue;else if(l.nodeType!==8)h+=a(l.childNodes)}return h}function b(g,h,l,m,q,p){q=0;for(var v=m.length;q<v;q++){var t=m[q];
if(t){t=t[g];for(var y=false;t;){if(t.sizcache===l){y=m[t.sizset];break}if(t.nodeType===1&&!p){t.sizcache=l;t.sizset=q}if(t.nodeName.toLowerCase()===h){y=t;break}t=t[g]}m[q]=y}}}function d(g,h,l,m,q,p){q=0;for(var v=m.length;q<v;q++){var t=m[q];if(t){t=t[g];for(var y=false;t;){if(t.sizcache===l){y=m[t.sizset];break}if(t.nodeType===1){if(!p){t.sizcache=l;t.sizset=q}if(typeof h!=="string"){if(t===h){y=true;break}}else if(k.filter(h,[t]).length>0){y=t;break}}t=t[g]}m[q]=y}}}var f=/((?:\((?:\([^()]+\)|[^()]+)+\)|\[(?:\[[^[\]]*\]|['"][^'"]*['"]|[^[\]'"]+)+\]|\\.|[^ >+~,(\[\\]+)+|[>+~])(\s*,\s*)?((?:.|\r|\n)*)/g,
e=0,j=Object.prototype.toString,i=false,o=true;[0,0].sort(function(){o=false;return 0});var k=function(g,h,l,m){l=l||[];var q=h=h||s;if(h.nodeType!==1&&h.nodeType!==9)return[];if(!g||typeof g!=="string")return l;for(var p=[],v,t,y,S,H=true,M=x(h),I=g;(f.exec(""),v=f.exec(I))!==null;){I=v[3];p.push(v[1]);if(v[2]){S=v[3];break}}if(p.length>1&&r.exec(g))if(p.length===2&&n.relative[p[0]])t=ga(p[0]+p[1],h);else for(t=n.relative[p[0]]?[h]:k(p.shift(),h);p.length;){g=p.shift();if(n.relative[g])g+=p.shift();
t=ga(g,t)}else{if(!m&&p.length>1&&h.nodeType===9&&!M&&n.match.ID.test(p[0])&&!n.match.ID.test(p[p.length-1])){v=k.find(p.shift(),h,M);h=v.expr?k.filter(v.expr,v.set)[0]:v.set[0]}if(h){v=m?{expr:p.pop(),set:z(m)}:k.find(p.pop(),p.length===1&&(p[0]==="~"||p[0]==="+")&&h.parentNode?h.parentNode:h,M);t=v.expr?k.filter(v.expr,v.set):v.set;if(p.length>0)y=z(t);else H=false;for(;p.length;){var D=p.pop();v=D;if(n.relative[D])v=p.pop();else D="";if(v==null)v=h;n.relative[D](y,v,M)}}else y=[]}y||(y=t);y||k.error(D||
g);if(j.call(y)==="[object Array]")if(H)if(h&&h.nodeType===1)for(g=0;y[g]!=null;g++){if(y[g]&&(y[g]===true||y[g].nodeType===1&&E(h,y[g])))l.push(t[g])}else for(g=0;y[g]!=null;g++)y[g]&&y[g].nodeType===1&&l.push(t[g]);else l.push.apply(l,y);else z(y,l);if(S){k(S,q,l,m);k.uniqueSort(l)}return l};k.uniqueSort=function(g){if(B){i=o;g.sort(B);if(i)for(var h=1;h<g.length;h++)g[h]===g[h-1]&&g.splice(h--,1)}return g};k.matches=function(g,h){return k(g,null,null,h)};k.find=function(g,h,l){var m,q;if(!g)return[];
for(var p=0,v=n.order.length;p<v;p++){var t=n.order[p];if(q=n.leftMatch[t].exec(g)){var y=q[1];q.splice(1,1);if(y.substr(y.length-1)!=="\\"){q[1]=(q[1]||"").replace(/\\/g,"");m=n.find[t](q,h,l);if(m!=null){g=g.replace(n.match[t],"");break}}}}m||(m=h.getElementsByTagName("*"));return{set:m,expr:g}};k.filter=function(g,h,l,m){for(var q=g,p=[],v=h,t,y,S=h&&h[0]&&x(h[0]);g&&h.length;){for(var H in n.filter)if((t=n.leftMatch[H].exec(g))!=null&&t[2]){var M=n.filter[H],I,D;D=t[1];y=false;t.splice(1,1);if(D.substr(D.length-
1)!=="\\"){if(v===p)p=[];if(n.preFilter[H])if(t=n.preFilter[H](t,v,l,p,m,S)){if(t===true)continue}else y=I=true;if(t)for(var U=0;(D=v[U])!=null;U++)if(D){I=M(D,t,U,v);var Ha=m^!!I;if(l&&I!=null)if(Ha)y=true;else v[U]=false;else if(Ha){p.push(D);y=true}}if(I!==w){l||(v=p);g=g.replace(n.match[H],"");if(!y)return[];break}}}if(g===q)if(y==null)k.error(g);else break;q=g}return v};k.error=function(g){throw"Syntax error, unrecognized expression: "+g;};var n=k.selectors={order:["ID","NAME","TAG"],match:{ID:/#((?:[\w\u00c0-\uFFFF-]|\\.)+)/,
CLASS:/\.((?:[\w\u00c0-\uFFFF-]|\\.)+)/,NAME:/\[name=['"]*((?:[\w\u00c0-\uFFFF-]|\\.)+)['"]*\]/,ATTR:/\[\s*((?:[\w\u00c0-\uFFFF-]|\\.)+)\s*(?:(\S?=)\s*(['"]*)(.*?)\3|)\s*\]/,TAG:/^((?:[\w\u00c0-\uFFFF\*-]|\\.)+)/,CHILD:/:(only|nth|last|first)-child(?:\((even|odd|[\dn+-]*)\))?/,POS:/:(nth|eq|gt|lt|first|last|even|odd)(?:\((\d*)\))?(?=[^-]|$)/,PSEUDO:/:((?:[\w\u00c0-\uFFFF-]|\\.)+)(?:\((['"]?)((?:\([^\)]+\)|[^\(\)]*)+)\2\))?/},leftMatch:{},attrMap:{"class":"className","for":"htmlFor"},attrHandle:{href:function(g){return g.getAttribute("href")}},
relative:{"+":function(g,h){var l=typeof h==="string",m=l&&!/\W/.test(h);l=l&&!m;if(m)h=h.toLowerCase();m=0;for(var q=g.length,p;m<q;m++)if(p=g[m]){for(;(p=p.previousSibling)&&p.nodeType!==1;);g[m]=l||p&&p.nodeName.toLowerCase()===h?p||false:p===h}l&&k.filter(h,g,true)},">":function(g,h){var l=typeof h==="string";if(l&&!/\W/.test(h)){h=h.toLowerCase();for(var m=0,q=g.length;m<q;m++){var p=g[m];if(p){l=p.parentNode;g[m]=l.nodeName.toLowerCase()===h?l:false}}}else{m=0;for(q=g.length;m<q;m++)if(p=g[m])g[m]=
l?p.parentNode:p.parentNode===h;l&&k.filter(h,g,true)}},"":function(g,h,l){var m=e++,q=d;if(typeof h==="string"&&!/\W/.test(h)){var p=h=h.toLowerCase();q=b}q("parentNode",h,m,g,p,l)},"~":function(g,h,l){var m=e++,q=d;if(typeof h==="string"&&!/\W/.test(h)){var p=h=h.toLowerCase();q=b}q("previousSibling",h,m,g,p,l)}},find:{ID:function(g,h,l){if(typeof h.getElementById!=="undefined"&&!l)return(g=h.getElementById(g[1]))?[g]:[]},NAME:function(g,h){if(typeof h.getElementsByName!=="undefined"){var l=[];
h=h.getElementsByName(g[1]);for(var m=0,q=h.length;m<q;m++)h[m].getAttribute("name")===g[1]&&l.push(h[m]);return l.length===0?null:l}},TAG:function(g,h){return h.getElementsByTagName(g[1])}},preFilter:{CLASS:function(g,h,l,m,q,p){g=" "+g[1].replace(/\\/g,"")+" ";if(p)return g;p=0;for(var v;(v=h[p])!=null;p++)if(v)if(q^(v.className&&(" "+v.className+" ").replace(/[\t\n]/g," ").indexOf(g)>=0))l||m.push(v);else if(l)h[p]=false;return false},ID:function(g){return g[1].replace(/\\/g,"")},TAG:function(g){return g[1].toLowerCase()},
CHILD:function(g){if(g[1]==="nth"){var h=/(-?)(\d*)n((?:\+|-)?\d*)/.exec(g[2]==="even"&&"2n"||g[2]==="odd"&&"2n+1"||!/\D/.test(g[2])&&"0n+"+g[2]||g[2]);g[2]=h[1]+(h[2]||1)-0;g[3]=h[3]-0}g[0]=e++;return g},ATTR:function(g,h,l,m,q,p){h=g[1].replace(/\\/g,"");if(!p&&n.attrMap[h])g[1]=n.attrMap[h];if(g[2]==="~=")g[4]=" "+g[4]+" ";return g},PSEUDO:function(g,h,l,m,q){if(g[1]==="not")if((f.exec(g[3])||"").length>1||/^\w/.test(g[3]))g[3]=k(g[3],null,null,h);else{g=k.filter(g[3],h,l,true^q);l||m.push.apply(m,
g);return false}else if(n.match.POS.test(g[0])||n.match.CHILD.test(g[0]))return true;return g},POS:function(g){g.unshift(true);return g}},filters:{enabled:function(g){return g.disabled===false&&g.type!=="hidden"},disabled:function(g){return g.disabled===true},checked:function(g){return g.checked===true},selected:function(g){return g.selected===true},parent:function(g){return!!g.firstChild},empty:function(g){return!g.firstChild},has:function(g,h,l){return!!k(l[3],g).length},header:function(g){return/h\d/i.test(g.nodeName)},
text:function(g){return"text"===g.type},radio:function(g){return"radio"===g.type},checkbox:function(g){return"checkbox"===g.type},file:function(g){return"file"===g.type},password:function(g){return"password"===g.type},submit:function(g){return"submit"===g.type},image:function(g){return"image"===g.type},reset:function(g){return"reset"===g.type},button:function(g){return"button"===g.type||g.nodeName.toLowerCase()==="button"},input:function(g){return/input|select|textarea|button/i.test(g.nodeName)}},
setFilters:{first:function(g,h){return h===0},last:function(g,h,l,m){return h===m.length-1},even:function(g,h){return h%2===0},odd:function(g,h){return h%2===1},lt:function(g,h,l){return h<l[3]-0},gt:function(g,h,l){return h>l[3]-0},nth:function(g,h,l){return l[3]-0===h},eq:function(g,h,l){return l[3]-0===h}},filter:{PSEUDO:function(g,h,l,m){var q=h[1],p=n.filters[q];if(p)return p(g,l,h,m);else if(q==="contains")return(g.textContent||g.innerText||a([g])||"").indexOf(h[3])>=0;else if(q==="not"){h=
h[3];l=0;for(m=h.length;l<m;l++)if(h[l]===g)return false;return true}else k.error("Syntax error, unrecognized expression: "+q)},CHILD:function(g,h){var l=h[1],m=g;switch(l){case "only":case "first":for(;m=m.previousSibling;)if(m.nodeType===1)return false;if(l==="first")return true;m=g;case "last":for(;m=m.nextSibling;)if(m.nodeType===1)return false;return true;case "nth":l=h[2];var q=h[3];if(l===1&&q===0)return true;h=h[0];var p=g.parentNode;if(p&&(p.sizcache!==h||!g.nodeIndex)){var v=0;for(m=p.firstChild;m;m=
m.nextSibling)if(m.nodeType===1)m.nodeIndex=++v;p.sizcache=h}g=g.nodeIndex-q;return l===0?g===0:g%l===0&&g/l>=0}},ID:function(g,h){return g.nodeType===1&&g.getAttribute("id")===h},TAG:function(g,h){return h==="*"&&g.nodeType===1||g.nodeName.toLowerCase()===h},CLASS:function(g,h){return(" "+(g.className||g.getAttribute("class"))+" ").indexOf(h)>-1},ATTR:function(g,h){var l=h[1];g=n.attrHandle[l]?n.attrHandle[l](g):g[l]!=null?g[l]:g.getAttribute(l);l=g+"";var m=h[2];h=h[4];return g==null?m==="!=":m===
"="?l===h:m==="*="?l.indexOf(h)>=0:m==="~="?(" "+l+" ").indexOf(h)>=0:!h?l&&g!==false:m==="!="?l!==h:m==="^="?l.indexOf(h)===0:m==="$="?l.substr(l.length-h.length)===h:m==="|="?l===h||l.substr(0,h.length+1)===h+"-":false},POS:function(g,h,l,m){var q=n.setFilters[h[2]];if(q)return q(g,l,h,m)}}},r=n.match.POS;for(var u in n.match){n.match[u]=new RegExp(n.match[u].source+/(?![^\[]*\])(?![^\(]*\))/.source);n.leftMatch[u]=new RegExp(/(^(?:.|\r|\n)*?)/.source+n.match[u].source.replace(/\\(\d+)/g,function(g,
h){return"\\"+(h-0+1)}))}var z=function(g,h){g=Array.prototype.slice.call(g,0);if(h){h.push.apply(h,g);return h}return g};try{Array.prototype.slice.call(s.documentElement.childNodes,0)}catch(C){z=function(g,h){h=h||[];if(j.call(g)==="[object Array]")Array.prototype.push.apply(h,g);else if(typeof g.length==="number")for(var l=0,m=g.length;l<m;l++)h.push(g[l]);else for(l=0;g[l];l++)h.push(g[l]);return h}}var B;if(s.documentElement.compareDocumentPosition)B=function(g,h){if(!g.compareDocumentPosition||
!h.compareDocumentPosition){if(g==h)i=true;return g.compareDocumentPosition?-1:1}g=g.compareDocumentPosition(h)&4?-1:g===h?0:1;if(g===0)i=true;return g};else if("sourceIndex"in s.documentElement)B=function(g,h){if(!g.sourceIndex||!h.sourceIndex){if(g==h)i=true;return g.sourceIndex?-1:1}g=g.sourceIndex-h.sourceIndex;if(g===0)i=true;return g};else if(s.createRange)B=function(g,h){if(!g.ownerDocument||!h.ownerDocument){if(g==h)i=true;return g.ownerDocument?-1:1}var l=g.ownerDocument.createRange(),m=
h.ownerDocument.createRange();l.setStart(g,0);l.setEnd(g,0);m.setStart(h,0);m.setEnd(h,0);g=l.compareBoundaryPoints(Range.START_TO_END,m);if(g===0)i=true;return g};(function(){var g=s.createElement("div"),h="script"+(new Date).getTime();g.innerHTML="<a name='"+h+"'/>";var l=s.documentElement;l.insertBefore(g,l.firstChild);if(s.getElementById(h)){n.find.ID=function(m,q,p){if(typeof q.getElementById!=="undefined"&&!p)return(q=q.getElementById(m[1]))?q.id===m[1]||typeof q.getAttributeNode!=="undefined"&&
q.getAttributeNode("id").nodeValue===m[1]?[q]:w:[]};n.filter.ID=function(m,q){var p=typeof m.getAttributeNode!=="undefined"&&m.getAttributeNode("id");return m.nodeType===1&&p&&p.nodeValue===q}}l.removeChild(g);l=g=null})();(function(){var g=s.createElement("div");g.appendChild(s.createComment(""));if(g.getElementsByTagName("*").length>0)n.find.TAG=function(h,l){l=l.getElementsByTagName(h[1]);if(h[1]==="*"){h=[];for(var m=0;l[m];m++)l[m].nodeType===1&&h.push(l[m]);l=h}return l};g.innerHTML="<a href='#'></a>";
if(g.firstChild&&typeof g.firstChild.getAttribute!=="undefined"&&g.firstChild.getAttribute("href")!=="#")n.attrHandle.href=function(h){return h.getAttribute("href",2)};g=null})();s.querySelectorAll&&function(){var g=k,h=s.createElement("div");h.innerHTML="<p class='TEST'></p>";if(!(h.querySelectorAll&&h.querySelectorAll(".TEST").length===0)){k=function(m,q,p,v){q=q||s;if(!v&&q.nodeType===9&&!x(q))try{return z(q.querySelectorAll(m),p)}catch(t){}return g(m,q,p,v)};for(var l in g)k[l]=g[l];h=null}}();
(function(){var g=s.createElement("div");g.innerHTML="<div class='test e'></div><div class='test'></div>";if(!(!g.getElementsByClassName||g.getElementsByClassName("e").length===0)){g.lastChild.className="e";if(g.getElementsByClassName("e").length!==1){n.order.splice(1,0,"CLASS");n.find.CLASS=function(h,l,m){if(typeof l.getElementsByClassName!=="undefined"&&!m)return l.getElementsByClassName(h[1])};g=null}}})();var E=s.compareDocumentPosition?function(g,h){return!!(g.compareDocumentPosition(h)&16)}:
function(g,h){return g!==h&&(g.contains?g.contains(h):true)},x=function(g){return(g=(g?g.ownerDocument||g:0).documentElement)?g.nodeName!=="HTML":false},ga=function(g,h){var l=[],m="",q;for(h=h.nodeType?[h]:h;q=n.match.PSEUDO.exec(g);){m+=q[0];g=g.replace(n.match.PSEUDO,"")}g=n.relative[g]?g+"*":g;q=0;for(var p=h.length;q<p;q++)k(g,h[q],l);return k.filter(m,l)};c.find=k;c.expr=k.selectors;c.expr[":"]=c.expr.filters;c.unique=k.uniqueSort;c.text=a;c.isXMLDoc=x;c.contains=E})();var eb=/Until$/,fb=/^(?:parents|prevUntil|prevAll)/,
gb=/,/;R=Array.prototype.slice;var Ia=function(a,b,d){if(c.isFunction(b))return c.grep(a,function(e,j){return!!b.call(e,j,e)===d});else if(b.nodeType)return c.grep(a,function(e){return e===b===d});else if(typeof b==="string"){var f=c.grep(a,function(e){return e.nodeType===1});if(Ua.test(b))return c.filter(b,f,!d);else b=c.filter(b,f)}return c.grep(a,function(e){return c.inArray(e,b)>=0===d})};c.fn.extend({find:function(a){for(var b=this.pushStack("","find",a),d=0,f=0,e=this.length;f<e;f++){d=b.length;
c.find(a,this[f],b);if(f>0)for(var j=d;j<b.length;j++)for(var i=0;i<d;i++)if(b[i]===b[j]){b.splice(j--,1);break}}return b},has:function(a){var b=c(a);return this.filter(function(){for(var d=0,f=b.length;d<f;d++)if(c.contains(this,b[d]))return true})},not:function(a){return this.pushStack(Ia(this,a,false),"not",a)},filter:function(a){return this.pushStack(Ia(this,a,true),"filter",a)},is:function(a){return!!a&&c.filter(a,this).length>0},closest:function(a,b){if(c.isArray(a)){var d=[],f=this[0],e,j=
{},i;if(f&&a.length){e=0;for(var o=a.length;e<o;e++){i=a[e];j[i]||(j[i]=c.expr.match.POS.test(i)?c(i,b||this.context):i)}for(;f&&f.ownerDocument&&f!==b;){for(i in j){e=j[i];if(e.jquery?e.index(f)>-1:c(f).is(e)){d.push({selector:i,elem:f});delete j[i]}}f=f.parentNode}}return d}var k=c.expr.match.POS.test(a)?c(a,b||this.context):null;return this.map(function(n,r){for(;r&&r.ownerDocument&&r!==b;){if(k?k.index(r)>-1:c(r).is(a))return r;r=r.parentNode}return null})},index:function(a){if(!a||typeof a===
"string")return c.inArray(this[0],a?c(a):this.parent().children());return c.inArray(a.jquery?a[0]:a,this)},add:function(a,b){a=typeof a==="string"?c(a,b||this.context):c.makeArray(a);b=c.merge(this.get(),a);return this.pushStack(qa(a[0])||qa(b[0])?b:c.unique(b))},andSelf:function(){return this.add(this.prevObject)}});c.each({parent:function(a){return(a=a.parentNode)&&a.nodeType!==11?a:null},parents:function(a){return c.dir(a,"parentNode")},parentsUntil:function(a,b,d){return c.dir(a,"parentNode",
d)},next:function(a){return c.nth(a,2,"nextSibling")},prev:function(a){return c.nth(a,2,"previousSibling")},nextAll:function(a){return c.dir(a,"nextSibling")},prevAll:function(a){return c.dir(a,"previousSibling")},nextUntil:function(a,b,d){return c.dir(a,"nextSibling",d)},prevUntil:function(a,b,d){return c.dir(a,"previousSibling",d)},siblings:function(a){return c.sibling(a.parentNode.firstChild,a)},children:function(a){return c.sibling(a.firstChild)},contents:function(a){return c.nodeName(a,"iframe")?
a.contentDocument||a.contentWindow.document:c.makeArray(a.childNodes)}},function(a,b){c.fn[a]=function(d,f){var e=c.map(this,b,d);eb.test(a)||(f=d);if(f&&typeof f==="string")e=c.filter(f,e);e=this.length>1?c.unique(e):e;if((this.length>1||gb.test(f))&&fb.test(a))e=e.reverse();return this.pushStack(e,a,R.call(arguments).join(","))}});c.extend({filter:function(a,b,d){if(d)a=":not("+a+")";return c.find.matches(a,b)},dir:function(a,b,d){var f=[];for(a=a[b];a&&a.nodeType!==9&&(d===w||a.nodeType!==1||!c(a).is(d));){a.nodeType===
1&&f.push(a);a=a[b]}return f},nth:function(a,b,d){b=b||1;for(var f=0;a;a=a[d])if(a.nodeType===1&&++f===b)break;return a},sibling:function(a,b){for(var d=[];a;a=a.nextSibling)a.nodeType===1&&a!==b&&d.push(a);return d}});var Ja=/ jQuery\d+="(?:\d+|null)"/g,V=/^\s+/,Ka=/(<([\w:]+)[^>]*?)\/>/g,hb=/^(?:area|br|col|embed|hr|img|input|link|meta|param)$/i,La=/<([\w:]+)/,ib=/<tbody/i,jb=/<|&#?\w+;/,ta=/<script|<object|<embed|<option|<style/i,ua=/checked\s*(?:[^=]|=\s*.checked.)/i,Ma=function(a,b,d){return hb.test(d)?
a:b+"></"+d+">"},F={option:[1,"<select multiple='multiple'>","</select>"],legend:[1,"<fieldset>","</fieldset>"],thead:[1,"<table>","</table>"],tr:[2,"<table><tbody>","</tbody></table>"],td:[3,"<table><tbody><tr>","</tr></tbody></table>"],col:[2,"<table><tbody></tbody><colgroup>","</colgroup></table>"],area:[1,"<map>","</map>"],_default:[0,"",""]};F.optgroup=F.option;F.tbody=F.tfoot=F.colgroup=F.caption=F.thead;F.th=F.td;if(!c.support.htmlSerialize)F._default=[1,"div<div>","</div>"];c.fn.extend({text:function(a){if(c.isFunction(a))return this.each(function(b){var d=
c(this);d.text(a.call(this,b,d.text()))});if(typeof a!=="object"&&a!==w)return this.empty().append((this[0]&&this[0].ownerDocument||s).createTextNode(a));return c.text(this)},wrapAll:function(a){if(c.isFunction(a))return this.each(function(d){c(this).wrapAll(a.call(this,d))});if(this[0]){var b=c(a,this[0].ownerDocument).eq(0).clone(true);this[0].parentNode&&b.insertBefore(this[0]);b.map(function(){for(var d=this;d.firstChild&&d.firstChild.nodeType===1;)d=d.firstChild;return d}).append(this)}return this},
wrapInner:function(a){if(c.isFunction(a))return this.each(function(b){c(this).wrapInner(a.call(this,b))});return this.each(function(){var b=c(this),d=b.contents();d.length?d.wrapAll(a):b.append(a)})},wrap:function(a){return this.each(function(){c(this).wrapAll(a)})},unwrap:function(){return this.parent().each(function(){c.nodeName(this,"body")||c(this).replaceWith(this.childNodes)}).end()},append:function(){return this.domManip(arguments,true,function(a){this.nodeType===1&&this.appendChild(a)})},
prepend:function(){return this.domManip(arguments,true,function(a){this.nodeType===1&&this.insertBefore(a,this.firstChild)})},before:function(){if(this[0]&&this[0].parentNode)return this.domManip(arguments,false,function(b){this.parentNode.insertBefore(b,this)});else if(arguments.length){var a=c(arguments[0]);a.push.apply(a,this.toArray());return this.pushStack(a,"before",arguments)}},after:function(){if(this[0]&&this[0].parentNode)return this.domManip(arguments,false,function(b){this.parentNode.insertBefore(b,
this.nextSibling)});else if(arguments.length){var a=this.pushStack(this,"after",arguments);a.push.apply(a,c(arguments[0]).toArray());return a}},remove:function(a,b){for(var d=0,f;(f=this[d])!=null;d++)if(!a||c.filter(a,[f]).length){if(!b&&f.nodeType===1){c.cleanData(f.getElementsByTagName("*"));c.cleanData([f])}f.parentNode&&f.parentNode.removeChild(f)}return this},empty:function(){for(var a=0,b;(b=this[a])!=null;a++)for(b.nodeType===1&&c.cleanData(b.getElementsByTagName("*"));b.firstChild;)b.removeChild(b.firstChild);
return this},clone:function(a){var b=this.map(function(){if(!c.support.noCloneEvent&&!c.isXMLDoc(this)){var d=this.outerHTML,f=this.ownerDocument;if(!d){d=f.createElement("div");d.appendChild(this.cloneNode(true));d=d.innerHTML}return c.clean([d.replace(Ja,"").replace(/=([^="'>\s]+\/)>/g,'="$1">').replace(V,"")],f)[0]}else return this.cloneNode(true)});if(a===true){ra(this,b);ra(this.find("*"),b.find("*"))}return b},html:function(a){if(a===w)return this[0]&&this[0].nodeType===1?this[0].innerHTML.replace(Ja,
""):null;else if(typeof a==="string"&&!ta.test(a)&&(c.support.leadingWhitespace||!V.test(a))&&!F[(La.exec(a)||["",""])[1].toLowerCase()]){a=a.replace(Ka,Ma);try{for(var b=0,d=this.length;b<d;b++)if(this[b].nodeType===1){c.cleanData(this[b].getElementsByTagName("*"));this[b].innerHTML=a}}catch(f){this.empty().append(a)}}else c.isFunction(a)?this.each(function(e){var j=c(this),i=j.html();j.empty().append(function(){return a.call(this,e,i)})}):this.empty().append(a);return this},replaceWith:function(a){if(this[0]&&
this[0].parentNode){if(c.isFunction(a))return this.each(function(b){var d=c(this),f=d.html();d.replaceWith(a.call(this,b,f))});if(typeof a!=="string")a=c(a).detach();return this.each(function(){var b=this.nextSibling,d=this.parentNode;c(this).remove();b?c(b).before(a):c(d).append(a)})}else return this.pushStack(c(c.isFunction(a)?a():a),"replaceWith",a)},detach:function(a){return this.remove(a,true)},domManip:function(a,b,d){function f(u){return c.nodeName(u,"table")?u.getElementsByTagName("tbody")[0]||
u.appendChild(u.ownerDocument.createElement("tbody")):u}var e,j,i=a[0],o=[],k;if(!c.support.checkClone&&arguments.length===3&&typeof i==="string"&&ua.test(i))return this.each(function(){c(this).domManip(a,b,d,true)});if(c.isFunction(i))return this.each(function(u){var z=c(this);a[0]=i.call(this,u,b?z.html():w);z.domManip(a,b,d)});if(this[0]){e=i&&i.parentNode;e=c.support.parentNode&&e&&e.nodeType===11&&e.childNodes.length===this.length?{fragment:e}:sa(a,this,o);k=e.fragment;if(j=k.childNodes.length===
1?(k=k.firstChild):k.firstChild){b=b&&c.nodeName(j,"tr");for(var n=0,r=this.length;n<r;n++)d.call(b?f(this[n],j):this[n],n>0||e.cacheable||this.length>1?k.cloneNode(true):k)}o.length&&c.each(o,Qa)}return this}});c.fragments={};c.each({appendTo:"append",prependTo:"prepend",insertBefore:"before",insertAfter:"after",replaceAll:"replaceWith"},function(a,b){c.fn[a]=function(d){var f=[];d=c(d);var e=this.length===1&&this[0].parentNode;if(e&&e.nodeType===11&&e.childNodes.length===1&&d.length===1){d[b](this[0]);
return this}else{e=0;for(var j=d.length;e<j;e++){var i=(e>0?this.clone(true):this).get();c.fn[b].apply(c(d[e]),i);f=f.concat(i)}return this.pushStack(f,a,d.selector)}}});c.extend({clean:function(a,b,d,f){b=b||s;if(typeof b.createElement==="undefined")b=b.ownerDocument||b[0]&&b[0].ownerDocument||s;for(var e=[],j=0,i;(i=a[j])!=null;j++){if(typeof i==="number")i+="";if(i){if(typeof i==="string"&&!jb.test(i))i=b.createTextNode(i);else if(typeof i==="string"){i=i.replace(Ka,Ma);var o=(La.exec(i)||["",
""])[1].toLowerCase(),k=F[o]||F._default,n=k[0],r=b.createElement("div");for(r.innerHTML=k[1]+i+k[2];n--;)r=r.lastChild;if(!c.support.tbody){n=ib.test(i);o=o==="table"&&!n?r.firstChild&&r.firstChild.childNodes:k[1]==="<table>"&&!n?r.childNodes:[];for(k=o.length-1;k>=0;--k)c.nodeName(o[k],"tbody")&&!o[k].childNodes.length&&o[k].parentNode.removeChild(o[k])}!c.support.leadingWhitespace&&V.test(i)&&r.insertBefore(b.createTextNode(V.exec(i)[0]),r.firstChild);i=r.childNodes}if(i.nodeType)e.push(i);else e=
c.merge(e,i)}}if(d)for(j=0;e[j];j++)if(f&&c.nodeName(e[j],"script")&&(!e[j].type||e[j].type.toLowerCase()==="text/javascript"))f.push(e[j].parentNode?e[j].parentNode.removeChild(e[j]):e[j]);else{e[j].nodeType===1&&e.splice.apply(e,[j+1,0].concat(c.makeArray(e[j].getElementsByTagName("script"))));d.appendChild(e[j])}return e},cleanData:function(a){for(var b,d,f=c.cache,e=c.event.special,j=c.support.deleteExpando,i=0,o;(o=a[i])!=null;i++)if(d=o[c.expando]){b=f[d];if(b.events)for(var k in b.events)e[k]?
c.event.remove(o,k):Ca(o,k,b.handle);if(j)delete o[c.expando];else o.removeAttribute&&o.removeAttribute(c.expando);delete f[d]}}});var kb=/z-?index|font-?weight|opacity|zoom|line-?height/i,Na=/alpha\([^)]*\)/,Oa=/opacity=([^)]*)/,ha=/float/i,ia=/-([a-z])/ig,lb=/([A-Z])/g,mb=/^-?\d+(?:px)?$/i,nb=/^-?\d/,ob={position:"absolute",visibility:"hidden",display:"block"},pb=["Left","Right"],qb=["Top","Bottom"],rb=s.defaultView&&s.defaultView.getComputedStyle,Pa=c.support.cssFloat?"cssFloat":"styleFloat",ja=
function(a,b){return b.toUpperCase()};c.fn.css=function(a,b){return X(this,a,b,true,function(d,f,e){if(e===w)return c.curCSS(d,f);if(typeof e==="number"&&!kb.test(f))e+="px";c.style(d,f,e)})};c.extend({style:function(a,b,d){if(!a||a.nodeType===3||a.nodeType===8)return w;if((b==="width"||b==="height")&&parseFloat(d)<0)d=w;var f=a.style||a,e=d!==w;if(!c.support.opacity&&b==="opacity"){if(e){f.zoom=1;b=parseInt(d,10)+""==="NaN"?"":"alpha(opacity="+d*100+")";a=f.filter||c.curCSS(a,"filter")||"";f.filter=
Na.test(a)?a.replace(Na,b):b}return f.filter&&f.filter.indexOf("opacity=")>=0?parseFloat(Oa.exec(f.filter)[1])/100+"":""}if(ha.test(b))b=Pa;b=b.replace(ia,ja);if(e)f[b]=d;return f[b]},css:function(a,b,d,f){if(b==="width"||b==="height"){var e,j=b==="width"?pb:qb;function i(){e=b==="width"?a.offsetWidth:a.offsetHeight;f!=="border"&&c.each(j,function(){f||(e-=parseFloat(c.curCSS(a,"padding"+this,true))||0);if(f==="margin")e+=parseFloat(c.curCSS(a,"margin"+this,true))||0;else e-=parseFloat(c.curCSS(a,
"border"+this+"Width",true))||0})}a.offsetWidth!==0?i():c.swap(a,ob,i);return Math.max(0,Math.round(e))}return c.curCSS(a,b,d)},curCSS:function(a,b,d){var f,e=a.style;if(!c.support.opacity&&b==="opacity"&&a.currentStyle){f=Oa.test(a.currentStyle.filter||"")?parseFloat(RegExp.$1)/100+"":"";return f===""?"1":f}if(ha.test(b))b=Pa;if(!d&&e&&e[b])f=e[b];else if(rb){if(ha.test(b))b="float";b=b.replace(lb,"-$1").toLowerCase();e=a.ownerDocument.defaultView;if(!e)return null;if(a=e.getComputedStyle(a,null))f=
a.getPropertyValue(b);if(b==="opacity"&&f==="")f="1"}else if(a.currentStyle){d=b.replace(ia,ja);f=a.currentStyle[b]||a.currentStyle[d];if(!mb.test(f)&&nb.test(f)){b=e.left;var j=a.runtimeStyle.left;a.runtimeStyle.left=a.currentStyle.left;e.left=d==="fontSize"?"1em":f||0;f=e.pixelLeft+"px";e.left=b;a.runtimeStyle.left=j}}return f},swap:function(a,b,d){var f={};for(var e in b){f[e]=a.style[e];a.style[e]=b[e]}d.call(a);for(e in b)a.style[e]=f[e]}});if(c.expr&&c.expr.filters){c.expr.filters.hidden=function(a){var b=
a.offsetWidth,d=a.offsetHeight,f=a.nodeName.toLowerCase()==="tr";return b===0&&d===0&&!f?true:b>0&&d>0&&!f?false:c.curCSS(a,"display")==="none"};c.expr.filters.visible=function(a){return!c.expr.filters.hidden(a)}}var sb=J(),tb=/<script(.|\s)*?\/script>/gi,ub=/select|textarea/i,vb=/color|date|datetime|email|hidden|month|number|password|range|search|tel|text|time|url|week/i,N=/=\?(&|$)/,ka=/\?/,wb=/(\?|&)_=.*?(&|$)/,xb=/^(\w+:)?\/\/([^\/?#]+)/,yb=/%20/g,zb=c.fn.load;c.fn.extend({load:function(a,b,d){if(typeof a!==
"string")return zb.call(this,a);else if(!this.length)return this;var f=a.indexOf(" ");if(f>=0){var e=a.slice(f,a.length);a=a.slice(0,f)}f="GET";if(b)if(c.isFunction(b)){d=b;b=null}else if(typeof b==="object"){b=c.param(b,c.ajaxSettings.traditional);f="POST"}var j=this;c.ajax({url:a,type:f,dataType:"html",data:b,complete:function(i,o){if(o==="success"||o==="notmodified")j.html(e?c("<div />").append(i.responseText.replace(tb,"")).find(e):i.responseText);d&&j.each(d,[i.responseText,o,i])}});return this},
serialize:function(){return c.param(this.serializeArray())},serializeArray:function(){return this.map(function(){return this.elements?c.makeArray(this.elements):this}).filter(function(){return this.name&&!this.disabled&&(this.checked||ub.test(this.nodeName)||vb.test(this.type))}).map(function(a,b){a=c(this).val();return a==null?null:c.isArray(a)?c.map(a,function(d){return{name:b.name,value:d}}):{name:b.name,value:a}}).get()}});c.each("ajaxStart ajaxStop ajaxComplete ajaxError ajaxSuccess ajaxSend".split(" "),
function(a,b){c.fn[b]=function(d){return this.bind(b,d)}});c.extend({get:function(a,b,d,f){if(c.isFunction(b)){f=f||d;d=b;b=null}return c.ajax({type:"GET",url:a,data:b,success:d,dataType:f})},getScript:function(a,b){return c.get(a,null,b,"script")},getJSON:function(a,b,d){return c.get(a,b,d,"json")},post:function(a,b,d,f){if(c.isFunction(b)){f=f||d;d=b;b={}}return c.ajax({type:"POST",url:a,data:b,success:d,dataType:f})},ajaxSetup:function(a){c.extend(c.ajaxSettings,a)},ajaxSettings:{url:location.href,
global:true,type:"GET",contentType:"application/x-www-form-urlencoded",processData:true,async:true,xhr:A.XMLHttpRequest&&(A.location.protocol!=="file:"||!A.ActiveXObject)?function(){return new A.XMLHttpRequest}:function(){try{return new A.ActiveXObject("Microsoft.XMLHTTP")}catch(a){}},accepts:{xml:"application/xml, text/xml",html:"text/html",script:"text/javascript, application/javascript",json:"application/json, text/javascript",text:"text/plain",_default:"*/*"}},lastModified:{},etag:{},ajax:function(a){function b(){e.success&&
e.success.call(k,o,i,x);e.global&&f("ajaxSuccess",[x,e])}function d(){e.complete&&e.complete.call(k,x,i);e.global&&f("ajaxComplete",[x,e]);e.global&&!--c.active&&c.event.trigger("ajaxStop")}function f(q,p){(e.context?c(e.context):c.event).trigger(q,p)}var e=c.extend(true,{},c.ajaxSettings,a),j,i,o,k=a&&a.context||e,n=e.type.toUpperCase();if(e.data&&e.processData&&typeof e.data!=="string")e.data=c.param(e.data,e.traditional);if(e.dataType==="jsonp"){if(n==="GET")N.test(e.url)||(e.url+=(ka.test(e.url)?
"&":"?")+(e.jsonp||"callback")+"=?");else if(!e.data||!N.test(e.data))e.data=(e.data?e.data+"&":"")+(e.jsonp||"callback")+"=?";e.dataType="json"}if(e.dataType==="json"&&(e.data&&N.test(e.data)||N.test(e.url))){j=e.jsonpCallback||"jsonp"+sb++;if(e.data)e.data=(e.data+"").replace(N,"="+j+"$1");e.url=e.url.replace(N,"="+j+"$1");e.dataType="script";A[j]=A[j]||function(q){o=q;b();d();A[j]=w;try{delete A[j]}catch(p){}z&&z.removeChild(C)}}if(e.dataType==="script"&&e.cache===null)e.cache=false;if(e.cache===
false&&n==="GET"){var r=J(),u=e.url.replace(wb,"$1_="+r+"$2");e.url=u+(u===e.url?(ka.test(e.url)?"&":"?")+"_="+r:"")}if(e.data&&n==="GET")e.url+=(ka.test(e.url)?"&":"?")+e.data;e.global&&!c.active++&&c.event.trigger("ajaxStart");r=(r=xb.exec(e.url))&&(r[1]&&r[1]!==location.protocol||r[2]!==location.host);if(e.dataType==="script"&&n==="GET"&&r){var z=s.getElementsByTagName("head")[0]||s.documentElement,C=s.createElement("script");C.src=e.url;if(e.scriptCharset)C.charset=e.scriptCharset;if(!j){var B=
false;C.onload=C.onreadystatechange=function(){if(!B&&(!this.readyState||this.readyState==="loaded"||this.readyState==="complete")){B=true;b();d();C.onload=C.onreadystatechange=null;z&&C.parentNode&&z.removeChild(C)}}}z.insertBefore(C,z.firstChild);return w}var E=false,x=e.xhr();if(x){e.username?x.open(n,e.url,e.async,e.username,e.password):x.open(n,e.url,e.async);try{if(e.data||a&&a.contentType)x.setRequestHeader("Content-Type",e.contentType);if(e.ifModified){c.lastModified[e.url]&&x.setRequestHeader("If-Modified-Since",
c.lastModified[e.url]);c.etag[e.url]&&x.setRequestHeader("If-None-Match",c.etag[e.url])}r||x.setRequestHeader("X-Requested-With","XMLHttpRequest");x.setRequestHeader("Accept",e.dataType&&e.accepts[e.dataType]?e.accepts[e.dataType]+", */*":e.accepts._default)}catch(ga){}if(e.beforeSend&&e.beforeSend.call(k,x,e)===false){e.global&&!--c.active&&c.event.trigger("ajaxStop");x.abort();return false}e.global&&f("ajaxSend",[x,e]);var g=x.onreadystatechange=function(q){if(!x||x.readyState===0||q==="abort"){E||
d();E=true;if(x)x.onreadystatechange=c.noop}else if(!E&&x&&(x.readyState===4||q==="timeout")){E=true;x.onreadystatechange=c.noop;i=q==="timeout"?"timeout":!c.httpSuccess(x)?"error":e.ifModified&&c.httpNotModified(x,e.url)?"notmodified":"success";var p;if(i==="success")try{o=c.httpData(x,e.dataType,e)}catch(v){i="parsererror";p=v}if(i==="success"||i==="notmodified")j||b();else c.handleError(e,x,i,p);d();q==="timeout"&&x.abort();if(e.async)x=null}};try{var h=x.abort;x.abort=function(){x&&h.call(x);
g("abort")}}catch(l){}e.async&&e.timeout>0&&setTimeout(function(){x&&!E&&g("timeout")},e.timeout);try{x.send(n==="POST"||n==="PUT"||n==="DELETE"?e.data:null)}catch(m){c.handleError(e,x,null,m);d()}e.async||g();return x}},handleError:function(a,b,d,f){if(a.error)a.error.call(a.context||a,b,d,f);if(a.global)(a.context?c(a.context):c.event).trigger("ajaxError",[b,a,f])},active:0,httpSuccess:function(a){try{return!a.status&&location.protocol==="file:"||a.status>=200&&a.status<300||a.status===304||a.status===
1223||a.status===0}catch(b){}return false},httpNotModified:function(a,b){var d=a.getResponseHeader("Last-Modified"),f=a.getResponseHeader("Etag");if(d)c.lastModified[b]=d;if(f)c.etag[b]=f;return a.status===304||a.status===0},httpData:function(a,b,d){var f=a.getResponseHeader("content-type")||"",e=b==="xml"||!b&&f.indexOf("xml")>=0;a=e?a.responseXML:a.responseText;e&&a.documentElement.nodeName==="parsererror"&&c.error("parsererror");if(d&&d.dataFilter)a=d.dataFilter(a,b);if(typeof a==="string")if(b===
"json"||!b&&f.indexOf("json")>=0)a=c.parseJSON(a);else if(b==="script"||!b&&f.indexOf("javascript")>=0)c.globalEval(a);return a},param:function(a,b){function d(i,o){if(c.isArray(o))c.each(o,function(k,n){b||/\[\]$/.test(i)?f(i,n):d(i+"["+(typeof n==="object"||c.isArray(n)?k:"")+"]",n)});else!b&&o!=null&&typeof o==="object"?c.each(o,function(k,n){d(i+"["+k+"]",n)}):f(i,o)}function f(i,o){o=c.isFunction(o)?o():o;e[e.length]=encodeURIComponent(i)+"="+encodeURIComponent(o)}var e=[];if(b===w)b=c.ajaxSettings.traditional;
if(c.isArray(a)||a.jquery)c.each(a,function(){f(this.name,this.value)});else for(var j in a)d(j,a[j]);return e.join("&").replace(yb,"+")}});var la={},Ab=/toggle|show|hide/,Bb=/^([+-]=)?([\d+-.]+)(.*)$/,W,va=[["height","marginTop","marginBottom","paddingTop","paddingBottom"],["width","marginLeft","marginRight","paddingLeft","paddingRight"],["opacity"]];c.fn.extend({show:function(a,b){if(a||a===0)return this.animate(K("show",3),a,b);else{a=0;for(b=this.length;a<b;a++){var d=c.data(this[a],"olddisplay");
this[a].style.display=d||"";if(c.css(this[a],"display")==="none"){d=this[a].nodeName;var f;if(la[d])f=la[d];else{var e=c("<"+d+" />").appendTo("body");f=e.css("display");if(f==="none")f="block";e.remove();la[d]=f}c.data(this[a],"olddisplay",f)}}a=0;for(b=this.length;a<b;a++)this[a].style.display=c.data(this[a],"olddisplay")||"";return this}},hide:function(a,b){if(a||a===0)return this.animate(K("hide",3),a,b);else{a=0;for(b=this.length;a<b;a++){var d=c.data(this[a],"olddisplay");!d&&d!=="none"&&c.data(this[a],
"olddisplay",c.css(this[a],"display"))}a=0;for(b=this.length;a<b;a++)this[a].style.display="none";return this}},_toggle:c.fn.toggle,toggle:function(a,b){var d=typeof a==="boolean";if(c.isFunction(a)&&c.isFunction(b))this._toggle.apply(this,arguments);else a==null||d?this.each(function(){var f=d?a:c(this).is(":hidden");c(this)[f?"show":"hide"]()}):this.animate(K("toggle",3),a,b);return this},fadeTo:function(a,b,d){return this.filter(":hidden").css("opacity",0).show().end().animate({opacity:b},a,d)},
animate:function(a,b,d,f){var e=c.speed(b,d,f);if(c.isEmptyObject(a))return this.each(e.complete);return this[e.queue===false?"each":"queue"](function(){var j=c.extend({},e),i,o=this.nodeType===1&&c(this).is(":hidden"),k=this;for(i in a){var n=i.replace(ia,ja);if(i!==n){a[n]=a[i];delete a[i];i=n}if(a[i]==="hide"&&o||a[i]==="show"&&!o)return j.complete.call(this);if((i==="height"||i==="width")&&this.style){j.display=c.css(this,"display");j.overflow=this.style.overflow}if(c.isArray(a[i])){(j.specialEasing=
j.specialEasing||{})[i]=a[i][1];a[i]=a[i][0]}}if(j.overflow!=null)this.style.overflow="hidden";j.curAnim=c.extend({},a);c.each(a,function(r,u){var z=new c.fx(k,j,r);if(Ab.test(u))z[u==="toggle"?o?"show":"hide":u](a);else{var C=Bb.exec(u),B=z.cur(true)||0;if(C){u=parseFloat(C[2]);var E=C[3]||"px";if(E!=="px"){k.style[r]=(u||1)+E;B=(u||1)/z.cur(true)*B;k.style[r]=B+E}if(C[1])u=(C[1]==="-="?-1:1)*u+B;z.custom(B,u,E)}else z.custom(B,u,"")}});return true})},stop:function(a,b){var d=c.timers;a&&this.queue([]);
this.each(function(){for(var f=d.length-1;f>=0;f--)if(d[f].elem===this){b&&d[f](true);d.splice(f,1)}});b||this.dequeue();return this}});c.each({slideDown:K("show",1),slideUp:K("hide",1),slideToggle:K("toggle",1),fadeIn:{opacity:"show"},fadeOut:{opacity:"hide"}},function(a,b){c.fn[a]=function(d,f){return this.animate(b,d,f)}});c.extend({speed:function(a,b,d){var f=a&&typeof a==="object"?a:{complete:d||!d&&b||c.isFunction(a)&&a,duration:a,easing:d&&b||b&&!c.isFunction(b)&&b};f.duration=c.fx.off?0:typeof f.duration===
"number"?f.duration:c.fx.speeds[f.duration]||c.fx.speeds._default;f.old=f.complete;f.complete=function(){f.queue!==false&&c(this).dequeue();c.isFunction(f.old)&&f.old.call(this)};return f},easing:{linear:function(a,b,d,f){return d+f*a},swing:function(a,b,d,f){return(-Math.cos(a*Math.PI)/2+0.5)*f+d}},timers:[],fx:function(a,b,d){this.options=b;this.elem=a;this.prop=d;if(!b.orig)b.orig={}}});c.fx.prototype={update:function(){this.options.step&&this.options.step.call(this.elem,this.now,this);(c.fx.step[this.prop]||
c.fx.step._default)(this);if((this.prop==="height"||this.prop==="width")&&this.elem.style)this.elem.style.display="block"},cur:function(a){if(this.elem[this.prop]!=null&&(!this.elem.style||this.elem.style[this.prop]==null))return this.elem[this.prop];return(a=parseFloat(c.css(this.elem,this.prop,a)))&&a>-10000?a:parseFloat(c.curCSS(this.elem,this.prop))||0},custom:function(a,b,d){function f(j){return e.step(j)}this.startTime=J();this.start=a;this.end=b;this.unit=d||this.unit||"px";this.now=this.start;
this.pos=this.state=0;var e=this;f.elem=this.elem;if(f()&&c.timers.push(f)&&!W)W=setInterval(c.fx.tick,13)},show:function(){this.options.orig[this.prop]=c.style(this.elem,this.prop);this.options.show=true;this.custom(this.prop==="width"||this.prop==="height"?1:0,this.cur());c(this.elem).show()},hide:function(){this.options.orig[this.prop]=c.style(this.elem,this.prop);this.options.hide=true;this.custom(this.cur(),0)},step:function(a){var b=J(),d=true;if(a||b>=this.options.duration+this.startTime){this.now=
this.end;this.pos=this.state=1;this.update();this.options.curAnim[this.prop]=true;for(var f in this.options.curAnim)if(this.options.curAnim[f]!==true)d=false;if(d){if(this.options.display!=null){this.elem.style.overflow=this.options.overflow;a=c.data(this.elem,"olddisplay");this.elem.style.display=a?a:this.options.display;if(c.css(this.elem,"display")==="none")this.elem.style.display="block"}this.options.hide&&c(this.elem).hide();if(this.options.hide||this.options.show)for(var e in this.options.curAnim)c.style(this.elem,
e,this.options.orig[e]);this.options.complete.call(this.elem)}return false}else{e=b-this.startTime;this.state=e/this.options.duration;a=this.options.easing||(c.easing.swing?"swing":"linear");this.pos=c.easing[this.options.specialEasing&&this.options.specialEasing[this.prop]||a](this.state,e,0,1,this.options.duration);this.now=this.start+(this.end-this.start)*this.pos;this.update()}return true}};c.extend(c.fx,{tick:function(){for(var a=c.timers,b=0;b<a.length;b++)a[b]()||a.splice(b--,1);a.length||
c.fx.stop()},stop:function(){clearInterval(W);W=null},speeds:{slow:600,fast:200,_default:400},step:{opacity:function(a){c.style(a.elem,"opacity",a.now)},_default:function(a){if(a.elem.style&&a.elem.style[a.prop]!=null)a.elem.style[a.prop]=(a.prop==="width"||a.prop==="height"?Math.max(0,a.now):a.now)+a.unit;else a.elem[a.prop]=a.now}}});if(c.expr&&c.expr.filters)c.expr.filters.animated=function(a){return c.grep(c.timers,function(b){return a===b.elem}).length};c.fn.offset="getBoundingClientRect"in s.documentElement?
function(a){var b=this[0];if(a)return this.each(function(e){c.offset.setOffset(this,a,e)});if(!b||!b.ownerDocument)return null;if(b===b.ownerDocument.body)return c.offset.bodyOffset(b);var d=b.getBoundingClientRect(),f=b.ownerDocument;b=f.body;f=f.documentElement;return{top:d.top+(self.pageYOffset||c.support.boxModel&&f.scrollTop||b.scrollTop)-(f.clientTop||b.clientTop||0),left:d.left+(self.pageXOffset||c.support.boxModel&&f.scrollLeft||b.scrollLeft)-(f.clientLeft||b.clientLeft||0)}}:function(a){var b=
this[0];if(a)return this.each(function(r){c.offset.setOffset(this,a,r)});if(!b||!b.ownerDocument)return null;if(b===b.ownerDocument.body)return c.offset.bodyOffset(b);c.offset.initialize();var d=b.offsetParent,f=b,e=b.ownerDocument,j,i=e.documentElement,o=e.body;f=(e=e.defaultView)?e.getComputedStyle(b,null):b.currentStyle;for(var k=b.offsetTop,n=b.offsetLeft;(b=b.parentNode)&&b!==o&&b!==i;){if(c.offset.supportsFixedPosition&&f.position==="fixed")break;j=e?e.getComputedStyle(b,null):b.currentStyle;
k-=b.scrollTop;n-=b.scrollLeft;if(b===d){k+=b.offsetTop;n+=b.offsetLeft;if(c.offset.doesNotAddBorder&&!(c.offset.doesAddBorderForTableAndCells&&/^t(able|d|h)$/i.test(b.nodeName))){k+=parseFloat(j.borderTopWidth)||0;n+=parseFloat(j.borderLeftWidth)||0}f=d;d=b.offsetParent}if(c.offset.subtractsBorderForOverflowNotVisible&&j.overflow!=="visible"){k+=parseFloat(j.borderTopWidth)||0;n+=parseFloat(j.borderLeftWidth)||0}f=j}if(f.position==="relative"||f.position==="static"){k+=o.offsetTop;n+=o.offsetLeft}if(c.offset.supportsFixedPosition&&
f.position==="fixed"){k+=Math.max(i.scrollTop,o.scrollTop);n+=Math.max(i.scrollLeft,o.scrollLeft)}return{top:k,left:n}};c.offset={initialize:function(){var a=s.body,b=s.createElement("div"),d,f,e,j=parseFloat(c.curCSS(a,"marginTop",true))||0;c.extend(b.style,{position:"absolute",top:0,left:0,margin:0,border:0,width:"1px",height:"1px",visibility:"hidden"});b.innerHTML="<div style='position:absolute;top:0;left:0;margin:0;border:5px solid #000;padding:0;width:1px;height:1px;'><div></div></div><table style='position:absolute;top:0;left:0;margin:0;border:5px solid #000;padding:0;width:1px;height:1px;' cellpadding='0' cellspacing='0'><tr><td></td></tr></table>";
a.insertBefore(b,a.firstChild);d=b.firstChild;f=d.firstChild;e=d.nextSibling.firstChild.firstChild;this.doesNotAddBorder=f.offsetTop!==5;this.doesAddBorderForTableAndCells=e.offsetTop===5;f.style.position="fixed";f.style.top="20px";this.supportsFixedPosition=f.offsetTop===20||f.offsetTop===15;f.style.position=f.style.top="";d.style.overflow="hidden";d.style.position="relative";this.subtractsBorderForOverflowNotVisible=f.offsetTop===-5;this.doesNotIncludeMarginInBodyOffset=a.offsetTop!==j;a.removeChild(b);
c.offset.initialize=c.noop},bodyOffset:function(a){var b=a.offsetTop,d=a.offsetLeft;c.offset.initialize();if(c.offset.doesNotIncludeMarginInBodyOffset){b+=parseFloat(c.curCSS(a,"marginTop",true))||0;d+=parseFloat(c.curCSS(a,"marginLeft",true))||0}return{top:b,left:d}},setOffset:function(a,b,d){if(/static/.test(c.curCSS(a,"position")))a.style.position="relative";var f=c(a),e=f.offset(),j=parseInt(c.curCSS(a,"top",true),10)||0,i=parseInt(c.curCSS(a,"left",true),10)||0;if(c.isFunction(b))b=b.call(a,
d,e);d={top:b.top-e.top+j,left:b.left-e.left+i};"using"in b?b.using.call(a,d):f.css(d)}};c.fn.extend({position:function(){if(!this[0])return null;var a=this[0],b=this.offsetParent(),d=this.offset(),f=/^body|html$/i.test(b[0].nodeName)?{top:0,left:0}:b.offset();d.top-=parseFloat(c.curCSS(a,"marginTop",true))||0;d.left-=parseFloat(c.curCSS(a,"marginLeft",true))||0;f.top+=parseFloat(c.curCSS(b[0],"borderTopWidth",true))||0;f.left+=parseFloat(c.curCSS(b[0],"borderLeftWidth",true))||0;return{top:d.top-
f.top,left:d.left-f.left}},offsetParent:function(){return this.map(function(){for(var a=this.offsetParent||s.body;a&&!/^body|html$/i.test(a.nodeName)&&c.css(a,"position")==="static";)a=a.offsetParent;return a})}});c.each(["Left","Top"],function(a,b){var d="scroll"+b;c.fn[d]=function(f){var e=this[0],j;if(!e)return null;if(f!==w)return this.each(function(){if(j=wa(this))j.scrollTo(!a?f:c(j).scrollLeft(),a?f:c(j).scrollTop());else this[d]=f});else return(j=wa(e))?"pageXOffset"in j?j[a?"pageYOffset":
"pageXOffset"]:c.support.boxModel&&j.document.documentElement[d]||j.document.body[d]:e[d]}});c.each(["Height","Width"],function(a,b){var d=b.toLowerCase();c.fn["inner"+b]=function(){return this[0]?c.css(this[0],d,false,"padding"):null};c.fn["outer"+b]=function(f){return this[0]?c.css(this[0],d,false,f?"margin":"border"):null};c.fn[d]=function(f){var e=this[0];if(!e)return f==null?null:this;if(c.isFunction(f))return this.each(function(j){var i=c(this);i[d](f.call(this,j,i[d]()))});return"scrollTo"in
e&&e.document?e.document.compatMode==="CSS1Compat"&&e.document.documentElement["client"+b]||e.document.body["client"+b]:e.nodeType===9?Math.max(e.documentElement["client"+b],e.body["scroll"+b],e.documentElement["scroll"+b],e.body["offset"+b],e.documentElement["offset"+b]):f===w?c.css(e,d):this.css(d,typeof f==="string"?f:f+"px")}});A.jQuery=A.$=c})(window);
EOF
}

1;
