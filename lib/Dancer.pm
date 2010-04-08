package Dancer;

use strict;
use warnings;
use Carp 'confess';
use vars qw($VERSION $AUTHORITY @EXPORT);

use Dancer::Config 'setting';
use Dancer::FileUtils;
use Dancer::GetOpt;
use Dancer::Error;
use Dancer::Helpers;
use Dancer::Logger;
use Dancer::Renderer;
use Dancer::Response;
use Dancer::Route;
use Dancer::Session;
use Dancer::SharedData;
use Dancer::Handler;
use Dancer::ModuleLoader;

use base 'Exporter';

$AUTHORITY = 'SUKRIA';
$VERSION   = '1.173_01';
@EXPORT    = qw(
  any
  before
  cookies
  config
  content_type
  dance
  debug
  del
  dirname
  error
  false
  from_json
  from_yaml
  from_xml
  get
  header
  headers
  layout
  load
  logger
  mime_type
  options
  params
  pass
  path
  post
  prefix
  put
  r
  redirect
  request
  send_file
  send_error
  set
  set_cookie
  session
  splat
  status
  template
  to_json
  to_yaml
  to_xml
  true
  upload
  uri_for
  var
  vars
  warning
);

# Dancer's syntax

sub any          { Dancer::Route->add_any(@_) }
sub before       { Dancer::Route->before_filter(@_) }
sub cookies      { Dancer::Cookies->cookies }
sub config       { Dancer::Config::settings() }
sub content_type { Dancer::Response::content_type(@_) }
sub debug        { Dancer::Logger->debug(@_) }
sub dirname      { Dancer::FileUtils::dirname(@_) }
sub error        { Dancer::Logger->error(@_) }
sub send_error   { Dancer::Helpers->error(@_) }
sub false        {0}
sub from_json    { Dancer::Serializer::JSON->deserialize(@_) }
sub from_yaml    { Dancer::Serializer::YAML->deserialize(@_) }
sub from_xml     { Dancer::Serializer::XML->deserialize(@_) }

sub get {
    Dancer::Route->add('head', @_);
    Dancer::Route->add('get',  @_);
}
sub headers    { Dancer::Response::headers(@_); }
sub header     { goto &headers; }                      # goto ftw!
sub layout     { set(layout => shift) }
sub logger     { set(logger => @_) }
sub load       { require $_ for @_ }
sub mime_type  { Dancer::Config::mime_types(@_) }
sub params     { Dancer::SharedData->request->params(@_) }
sub pass       { Dancer::Response->pass }
sub path       { Dancer::FileUtils::path(@_) }
sub post       { Dancer::Route->add('post', @_) }
sub prefix     { Dancer::Route->prefix(@_) }
sub del        { Dancer::Route->add('delete', @_) }
sub options    { Dancer::Route->add('options', @_) }
sub put        { Dancer::Route->add('put', @_) }
sub r          { {regexp => $_[0]} }
sub redirect   { Dancer::Helpers::redirect(@_) }
sub request    { Dancer::SharedData->request }
sub send_file  { Dancer::Helpers::send_file(@_) }
sub set        { setting(@_) }
sub set_cookie { Dancer::Helpers::set_cookie(@_) }

sub session {
    if (@_ == 0) {
        return Dancer::Session->get;
    }
    else {
        return (@_ == 1)
          ? Dancer::Session->read(@_)
          : Dancer::Session->write(@_);
    }
}
sub splat    { @{ Dancer::SharedData->request->params->{splat} } }
sub status   { Dancer::Response::status(@_) }
sub template { Dancer::Helpers::template(@_) }
sub true     {1}
sub to_json  { Dancer::Serializer::JSON->serialize(@_) }
sub to_yaml  { Dancer::Serializer::YAML->serialize(@_) }
sub to_xml   { Dancer::Serializer::XML->serialize(@_) }
sub upload   { Dancer::SharedData->request->upload(@_) }
sub uri_for  { Dancer::SharedData->request->uri_for(@_) }
sub var      { Dancer::SharedData->var(@_) }
sub vars     { Dancer::SharedData->vars }
sub warning  { Dancer::Logger->warning(@_) }

# When importing the package, strict and warnings pragma are loaded,
# and the appdir detection is performed.
sub import {
    my ( $class,   $symbol ) = @_;
    my ( $package, $script ) = caller;

    strict->import;
    warnings->import;

    for my $name (qw/JSON YAML XML/) {
        my $module = "Dancer::Serializer::$name";
        if ( Dancer::ModuleLoader->load($module) ) {
            $module->init;
        }
    }

    $class->export_to_level( 1, $class, @EXPORT );

    # if :syntax option exists, don't change settings
    if ( $symbol && $symbol eq ':syntax' ) {
        return;
    }

    Dancer::GetOpt->process_args();
    setting appdir  => dirname( File::Spec->rel2abs($script) );
    setting public  => path( setting('appdir'), 'public' );
    setting views   => path( setting('appdir'), 'views' );
    setting logger  => 'file';
    setting confdir => $ENV{DANCER_CONFDIR} || setting('appdir');
    Dancer::Config->load;
}

# Start/Run the application with the chosen apphandler
sub dance {
    my ($class, $request) = @_;
    Dancer::Config->load;
    Dancer::Handler->get_handler()->dance($request);
}

1;
__END__

=pod

=head1 NAME

Dancer - Lightweight yet powerful web application framework


=head1 SYNOPSIS

    #!/usr/bin/perl
    use Dancer;

    get '/hello/:name' => sub {
        return "Why, hello there " . params->{name};
    };

    dance;

The above is a basic but functional web app created with Dancer.  If you want
to see more examples and get up and running quickly, check out the
L<Dancer::Introduction> and the L<Dancer::Cookbook>.  For examples on
deploying your Dancer applications, see L<Dancer::Deployment>.

=head1 DESCRIPTION

Dancer is a web application framework designed to be as effortless as possible
for the developer, taking care of the boring bits as easily as possible, yet
staying out of your way and letting you get on with writing your code.

Dancer aims to provide the simplest way for writing web applications, and
offers the flexibility to scale between a very simple lightweight web service
consisting of a few lines of code in a single file, all the way up to a more
complex fully-fledged web application with session support, templates for views
and layouts, etc.

If you don't want to write CGI scripts by hand, and find Catalyst too big or
cumbersome for your project, Dancer is what you need.

Dancer has few pre-requisites, so your Dancer webapps will be easy to deploy.

Dancer apps can be used with a an embedded web server (great for easy testing),
and can run under PSGI/Plack for easy deployment in a variety of webserver
environments.

=head1 METHODS

=head2 any

Define a route for multiple methods at one.

    any ['get', 'post'] => '/myaction' => sub {
        # code
    };

Or even, a route handler that would match any HTTP methods:

    any '/myaction' => sub {
        # code
    };

=head2 before

=head2 cookies

Access cookies values, which returns a hashref of Cookies objects:

    get '/some_action' => sub {
        my $cookie = cookies->{name};
        return $cookie->value;
    };

=head2 config

Access the configuration of the application:

    get '/appname' => sub {
        return "This is " . config->{appname};
    };

=head2 content_type

Set the B<content-type> rendered :

    get '/cat/:txtfile' => sub {
        content_type 'text/plain';

        # here we can dump the contents of params->{txtfile}
    };

=head2 debug

Log a message of debug level

    debug "This is a debug message";

=head2 dirname

=head2 error

Log a message of error level:

    error "This is an error message";

=head2 send_error

The application return an error. By default the HTTP code returned is 500.

    get '/photo/:id' => sub {
        if (...) {
            send_error("Not allowed", 403);
        } else {
           # return content
        }
    }

=head2 false

=head2 from_json

Deserialize a JSON structure

=head2 from_yaml

Deserialize a YAML structure

=head2 from_xml

Deserialize a XML structur

=head2 get

Define a route for B<GET> method.

    get '/' => sub {
        return "Hello world";
    }

=head2 headers

Add custom headers to responses:

    get '/send/headers', sub {
        headers 'X-Foo' => 'bar', X-Bar => 'foo';
    }

=head2 header

Add a custom header to response:

    get '/send/header', sub {
        header 'X-My-Header' => 'shazam!';
    }

=head2 layout

=head2 logger

=head2 load

=head2 mime_type

=head2 params

=head2 pass

=head2 path

=head2 post

=head2 prefix

A prefix can be defined for each route handler, like this:

    prefix '/home';

From here, any route handler is defined to /home/*

    get '/page1' => sub {}; # will match '/home/page1'

You can unset the prefix value

    prefix undef;
    get '/page1' => sub {}; will match /page1

=head2 del

=head2 options

=head2 put

=head2 r

=head2 redirect

=head2 request

=head2 send_file

=head2 set

=head2 set_cookie

=head2 session

=head2 splat

=head2 status

=head2 template

=head2 to_json

Serialize a structure to JSON

=head2 to_yaml

Serialize a structure to YAML

=head2 to_xml

Serialize a struture to XML

=head2 upload

=head2 uri_for

=head2 var

=head2 vars

=head2 warning

=head1 AUTHOR

This module has been written by Alexis Sukrieh <sukria@cpan.org> and others,
see the AUTHORS file that comes with this distribution for details.

=head1 SOURCE CODE

The source code for this module is hosted on GitHub
L<http://github.com/sukria/Dancer>


=head1 GETTING HELP / CONTRIBUTING

The Dancer development team can be found on #dancer on irc.perl.org:
L<irc://irc.perl.org/dancer>

There is also a Dancer users mailing list available - subscribe at:

L<http://lists.perldancer.org/cgi-bin/listinfo/dancer-users>


=head1 DEPENDENCIES

Dancer depends on the following modules:

The following modules are mandatory (Dancer cannot run without them)

=over 8

=item L<HTTP::Server::Simple::PSGI>

=item L<HTTP::Body>

=item L<MIME::Types>

=item L<URI>

=back

The following modules are optional

=over 8

=item L<Template> : In order to use TT for rendering views

=item L<YAML> : needed for configuration file support

=item L<File::MimeInfo::Simple>

=back

=head1 LICENSE

This module is free software and is published under the same
terms as Perl itself.

=head1 SEE ALSO

Main Dancer web site: L<http://perldancer.org/>.

The concept behind this module comes from the Sinatra ruby project,
see L<http://www.sinatrarb.com/> for details.

=cut
