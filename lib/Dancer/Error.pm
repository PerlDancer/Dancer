package Dancer::Error;
our $AUTHORITY = 'cpan:SUKRIA';
#ABSTRACT: class for representing fatal errors
$Dancer::Error::VERSION = '1.3202';
use strict;
use warnings;
use Carp;
use Scalar::Util qw(blessed);

use base 'Dancer::Object';

use Dancer::Response;
use Dancer::Renderer;
use Dancer::Config 'setting';
use Dancer::Logger;
use Dancer::Factory::Hook;
use Dancer::Session;
use Dancer::FileUtils qw(open_file);
use Dancer::Engine;
use Dancer::Exception qw(:all);

Dancer::Factory::Hook->instance->install_hooks(
    qw/before_error_render after_error_render before_error_init/);

sub init {
    my ($self) = @_;

    Dancer::Factory::Hook->instance->execute_hooks('before_error_init', $self);

    $self->attributes_defaults(
        title => 'Error ' . $self->code,
        type  => 'runtime error',
    );

    $self->has_serializer
      and return;

    my $html_output = "<h2>" . $self->{type} . "</h2>";
    $html_output .= $self->backtrace;
    $html_output .= $self->environment;

    $self->{message} = $html_output;
}

sub has_serializer { setting('serializer') }
sub code           { $_[0]->{code} }
sub title          { $_[0]->{title} }
sub message        { $_[0]->{message} }
sub exception      { $_[0]->{exception} }

sub backtrace {
    my ($self) = @_;

    $self->{message} ||= "";
    my $message =
      qq|<pre class="error">| . _html_encode($self->{message}) . "</pre>";

    # the default perl warning/error pattern
    my ($file, $line) = ($message =~ /at (\S+) line (\d+)/);

    # the Devel::SimpleTrace pattern
    ($file, $line) = ($message =~ /at.*\((\S+):(\d+)\)/)
      unless $file and $line;

    # no file/line found, cannot open a file for context
    return $message unless ($file and $line);

    # file and line are located, let's read the source Luke!
    my $fh = open_file('<', $file) or return $message;
    my @lines = <$fh>;
    close $fh;

    my $backtrace = $message;

    $backtrace
      .= qq|<div class="title">| . "$file around line $line" . "</div>";

    $backtrace .= qq|<pre class="content">|;

    $line--;
    my $start = (($line - 3) >= 0)             ? ($line - 3) : 0;
    my $stop  = (($line + 3) < scalar(@lines)) ? ($line + 3) : scalar(@lines);

    for (my $l = $start; $l <= $stop; $l++) {
        chomp $lines[$l];

        if ($l == $line) {
            $backtrace
              .= qq|<span class="nu">|
              . tabulate($l + 1, $stop + 1)
              . qq|</span> <span style="color: red;">|
              . _html_encode($lines[$l])
              . "</span>\n";
        }
        else {
            $backtrace
              .= qq|<span class="nu">|
              . tabulate($l + 1, $stop + 1)
              . "</span> "
              . _html_encode($lines[$l]) . "\n";
        }
    }
    $backtrace .= "</pre>";


    return $backtrace;
}

sub tabulate {
    my ($number, $max) = @_;
    my $len = length($max);
    return $number if length($number) == $len;
    return " $number";
}

sub dumper {
    my $obj = shift;
    return "Unavailable without Data::Dumper"
      unless Dancer::ModuleLoader->load('Data::Dumper');


    # Take a copy of the data, so we can mask sensitive-looking stuff:
    my $data     = Dancer::ModuleLoader->load('Clone') ?
                   Clone::clone($obj)
                   : eval Data::Dumper->new([$obj])->Purity(1)->Terse(1)->Deepcopy(1)->Dump;

    $data = {%$data} if blessed($data); 

	my $censored = _censor($data);

    #use Data::Dumper;
    my $dd = Data::Dumper->new([$data]);
    $dd->Terse(1)->Quotekeys(0)->Indent(1)->Sortkeys(1);
    my $content = $dd->Dump();
    $content =~ s{(\s*)(\S+)(\s*)=>}{$1<span class="key">$2</span>$3 =&gt;}g;
    if ($censored) {
        $content
            .= "\n\nNote: Values of $censored sensitive-looking key"
            . ($censored == 1 ? '' : 's')
            . " hidden\n";
    }
    return $content;
}

# Given a hashref, censor anything that looks sensitive.  Returns number of
# items which were "censored".
sub _censor {
    my ( $hash, $recursecount ) = @_;
    $recursecount ||= 0;

    # we're checking recursion ourselves, no need to warn
    no warnings 'recursion';

    if ( $recursecount++ > 100 ) {
        warn "Data exceeding 100 levels, truncating\n";
        return $hash;
    }

    if (!$hash || ref $hash ne 'HASH') {
        carp "_censor given incorrect input: $hash";
        return;
    }

    my $censored = 0;
    for my $key (keys %$hash) {
        if (ref $hash->{$key} eq 'HASH') {
            $censored += _censor( $hash->{$key}, $recursecount );
        }
        elsif ($key =~ /(pass|card?num|pan|cvv|cvv2|ccv|secret|private_key)/i) {
            $hash->{$key} = "Hidden (looks potentially sensitive)";
            $censored++;
        }
    }

    return $censored;
}

# Replaces the entities that are illegal in (X)HTML.
sub _html_encode {
    my $value = shift;

    $value =~ s/&/&amp;/g;
    $value =~ s/</&lt;/g;
    $value =~ s/>/&gt;/g;
    $value =~ s/'/&#39;/g;
    $value =~ s/"/&quot;/g;

    return $value;
}

sub render {
    my $self = shift;

    my $serializer = setting('serializer');
    Dancer::Factory::Hook->instance->execute_hooks('before_error_render', $self);
    my $response;
    try {
        $response = $serializer ? $self->_render_serialized() : $self->_render_html();
    } continuation {
        my ($continuation) = @_;
        # If we have a Route continuation, run the after hook, then
        # propagate the continuation
        Dancer::Factory::Hook->instance->execute_hooks('after_error_render', $response);
        $continuation->rethrow();
    };
    Dancer::Factory::Hook->instance->execute_hooks('after_error_render', $response);
    $response;
}

sub _render_serialized {
    my $self = shift;

    my $message =
      !ref $self->message ? {error => $self->message} : $self->message;

    if (ref $message eq 'HASH' && defined $self->exception) {
        if (blessed($self->exception)) {
            $message->{exception} = ref($self->exception);
            $message->{exception} =~ s/^Dancer::Exception:://;
        } else {
            $message->{exception} = $self->exception;
        }
    }

    if (setting('show_errors')) {
        Dancer::Response->new(
            status  => $self->code,
            content => Dancer::Serializer->engine->serialize($message),
            headers => ['Content-Type' => Dancer::Serializer->engine->content_type]
            );
    }

    # if show_errors is disabled, we don't expose the real error message to the
    # outside world
    else {
        Dancer::Response->new(
            status => $self->code,
            content => "An internal error occured",
        );
    }

}

sub _render_html {
    my $self = shift;

    # I think it is irrelevant to look into show_errors. In the
    # template the user can hide them if she desires so.
    if (setting("error_template")) {
        my $template_name = setting("error_template");
        my $ops = {
                   title => $self->title,
                   message => $self->message,
                   code => $self->code,
                   defined $self->exception ? ( exception => $self->exception ) : (),
                  };
        my $content = Dancer::Engine->engine("template")->apply_renderer($template_name, $ops);
        return Dancer::Response->new(
            status => $self->code,
            headers => ['Content-Type' => 'text/html'],
            content => $content);
    } else {
        return Dancer::Response->new(
            status  => $self->code,
            headers => ['Content-Type' => 'text/html'],
            content =>
                Dancer::Renderer->html_page($self->title, $self->message, 'error')
        ) if setting('show_errors');

        return Dancer::Renderer->render_error($self->code);
    }
}

sub environment {
    my ($self) = @_;

    my $request = Dancer::SharedData->request;
    my $r_env   = {};
    $r_env = $request->env if defined $request;

    my $env =
        qq|<div class="title">Environment</div><pre class="content">|
      . dumper($r_env)
      . "</pre>";
    my $settings =
        qq|<div class="title">Settings</div><pre class="content">|
      . dumper(Dancer::Config->settings)
      . "</pre>";
    my $source =
        qq|<div class="title">Stack</div><pre class="content">|
      . $self->get_caller
      . "</pre>";
    my $session = "";

    if (setting('session')) {
        $session =
            qq[<div class="title">Session</div><pre class="content">]
          . dumper(Dancer::Session->get)
          . "</pre>";
    }
    return "$source $settings $session $env";
}

sub get_caller {
    my ($self) = @_;
    my @stack;

    my $deepness = 0;
    while (my ($package, $file, $line) = caller($deepness++)) {
        push @stack, "$package in $file l. $line";
    }

    return join("\n", reverse(@stack));
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dancer::Error - class for representing fatal errors

=head1 VERSION

version 1.3202

=head1 SYNOPSIS

    # taken from send_file:
    use Dancer::Error;

    my $error = Dancer::Error->new(
        code    => 404,
        message => "No such file: `$path'"
    );

    $error->render;

=head1 DESCRIPTION

With Dancer::Error you can throw reasonable-looking errors to the user instead
of crashing the application and filling up the logs.

This is usually used in debugging environments, and it's what Dancer uses as
well under debugging to catch errors and show them on screen.

=head1 ATTRIBUTES

=head2 code

The code that caused the error.

This is only an attribute getter, you'll have to set it at C<new>.

=head2 title

The title of the error page.

This is only an attribute getter, you'll have to set it at C<new>.

=head2 message

The message of the error page.

This is only an attribute getter, you'll have to set it at C<new>.

=head2 exception

The exception that caused the error. If the error was not caused by an
exception, returns undef. Exceptions are usually objects that inherit from
Dancer::Exception.

This is only an attribute getter, you'll have to set it at C<new>.

=head1 METHODS/SUBROUTINES

=head2 new

Create a new Dancer::Error object.

=head3 title

The title of the error page.

=head3 type

What type of error this is.

=head3 code

The code that caused the error.

=head3 message

The message that will appear to the user.

=head3 exception

The exception that will be useable by the rendering.

=head2 backtrace

Create a backtrace of the code where the error is caused.

This method tries to find out where the error appeared according to the actual
error message (using the C<message> attribute) and tries to parse it (supporting
the regular/default Perl warning or error pattern and the L<Devel::SimpleTrace>
output) and then returns an error-highlighted C<message>.

=head2 tabulate

Small subroutine to help output nicer.

=head2 dumper

This uses L<Data::Dumper> to create nice content output with a few predefined
options.

=head2 render

Renders a response using L<Dancer::Response>.

=head2 environment

A main function to render environment information: the caller (using
C<get_caller>), the settings and environment (using C<dumper>) and more.

=head2 get_caller

Creates a stack trace of callers.

=head2 _censor

An internal method that tries to censor out content which should be protected.

C<dumper> calls this method to censor things like passwords and such.

=head2 _html_encode

Internal method to encode entities that are illegal in (X)HTML. We output as
UTF-8, so no need to encode all non-ASCII characters or use a module.
FIXME : this is not true any more, output can be any charset. Need fixing.

=head1 AUTHOR

Dancer Core Developers

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Alexis Sukrieh.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
