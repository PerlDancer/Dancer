                                    Dancer

                  The easiest way to write a webapp with Perl                                    

=== ABOUT ===

This project is inspired by  Ruby's Sinatra framework: a framework for building
web applications with minimal effort, allowing a simple webapp to be created with
very few lines of code, but allowing the flexibility to scale to much more
complex applications.  Dancer supports plugins to add various extra
functionality you may want, whilst keeping the core streamlined.


=== NEWS === 

Dancer's development moves very quickly, to stay tuned follow PerlDancer on
Twitter: http://twitter.com/PerlDancer

See also Sukria's blog: http://www.sukria.net/fr/archives/tag/dancer/

See also the project on Github for the latest changes:

http://github.com/PerlDancer/Dancer

To keep even more up to date and talk to the developers, join us in #dancer on
irc.perl.org (if you don't have an IRC client, use http://www.perldancer.org/irc
for easy access).

=== EXAMPLE ===

To create a new Dancer application, use the helper script "dancer" provided
with this distribution:

    $ dancer -a MyWeb::App
    + MyWeb-App/bin
    + MyWeb-App/bin/app.pl
    + MyWeb-App/config.yml
    + MyWeb-App/environments
    [..]

You then have a new Dancer application in 'MyWeb::App', which is already a
functioning "Hello World" application, ready for you to work upon.

Here is an example of a webapp built with Dancer:

    # MyWeb-App/bin/app.pl
    #!/usr/bin/perl

    use Dancer;

    get '/' => sub {
        "Hello There!"
    };

    get '/hello/:name' => sub {
        "Hey ".params->{name}.", how are you?";
    };

    post '/new' => sub {
        "creating new entry: ".params->{name};
    };

    Dancer->dance;

When running this script, a webserver is running and ready to serve:    

    $ perl ./bin/app.pl
    >> Listening on 0.0.0.0:3000
    == Entering the development dance floor ...

Then it's possible to access any route defined in the script:

    $ curl http://localhost:3000/
    Hello There!

For a more in-depth example, see examples/dancr


=== DEPENDENCIES ===

Dancer depends on the following modules

    - HTTP::Server::Simple::PSGI
    - HTTP::Body
    - Exception::Class
	- MIME::Types
	- URI

Optional modules may be needed if you want to use some features (but are not 
required for a basic usage). 

Dependency-checks for additional features are performed at runtime.

Most common modules you may want are:

    - Template (for Template::Toolkit support)
    - YAML (for configuration files)
    - Plack (if you want to deploy your application with PSGI)


=== PRODUCTION MATTERS ===

This is a work in progress.

Dancer supports PSGI/Plack, to run a Dancer app with PSGI/Plack just bootstrap
your application with the helper script `dancer' like the following:

	$ dancer -a MyWeb::App

You'll find a file in there called `app.psgi', use this file to configure your
PSGI environment, as explained in the revelant documentation of your PSGI
server.

For instance, with plackup, just do the following:

	$ plackup -a app.psgi


=== WEBSITE ===

For more details about the project, checkout the official website:
http://perldancer.org/ or checkout the documentation at
http://search.cpan.org/dist/Dancer/

See also the Github project page: http://github.com/PerlDancer/Dancer for the latest
changes.


=== REPORTING BUGS ===

Bug reports are appreciated and will receive prompt attention - the preferred
method is to raise them using Github's basic issue tracking system:

http://github.com/PerlDancer/Dancer/issues



=== CONTACT ===

You can reach the development team on IRC: irc://irc.perl.org/#dancer or
http://www.perldancer.org/irc for a web-based IRC client.



